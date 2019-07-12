#!/bin/bash
THIS="${0##*/}"
CDIR=$([ -n "${0%/*}" ] && cd "${0%/*}" 2>/dev/null; pwd)

# Name
THIS="${THIS:-install.sh}"
BASE="${THIS%%.*}"

# Path
PARH=/usr/bin:/bin; export PATH

# Platform
DOT_SSHCONF_OS=$(uname -s|tr '[A-Z]' '[a-z]')

# dot-ssh-files URL
DOT_SSHCNF_URL="${DOT_SSHCNF_URL:-https://github.com/mtangh/dot-ssh-files.git}"

# XDG Config Dir
DOT_SSH_XDGCNF="${XDG_CONFIG_HOME:-$HOME/.config}"

# Install Dir
DOT_SSHCNF_XDG="${DOT_SSHCNF_XDG:-$DOT_SSH_XDGCNF/dot-ssh-files}"

# SSH Config Dir
DOT_SSHCNF_DIR="${DOT_SSHCNF_DIR:-$HOME/.ssh}"

# Temp die
DOT_SSHCNF_TMP="${TMPDIR:-/tmp}/.${BASE}.$$"

# Git
dot_sshcnf_git="$(type -P git)"

# Flags
_x_dryrun_mode=0
_xtrace_enable=0

# Debug
case "${DEBUG:-NO}" in
0|[Nn][Oo]|[Oo][Ff][Ff])
  ;;
*)
  _x_dryrun_mode=1
  _xtrace_enable=1
  ;;
esac || :

# Cleanup
_cleanup() {
  [ -n "${DOT_SSHCNF_TMP}" ] && {
    rm -rf "${DOT_SSHCNF_TMP}"
  }  1>/dev/null 2>&1 || :
  return 0
}

# Parsing command line options
while [ $# -gt 0 ]
do
  case "$1" in
  -D*|-debug*|--debug*)
    _xtrace_enable=1
    ;;
  -n*|-dry-run*|--dry-run*)
    _x_dryrun_mode=1
    ;;
  -*)
    echo "$THIS: ERROE: Illegal option '${1}'." 1>&2
    exit 1
    ;;
  *)
    ;;
  esac
  shift
done

# Check
[ -x "${dot_sshcnf_git}" ] || {
  echo "$THIS: ERROR: '${dot_sshcnf_git}': Command not found." 1>&2
  exit 1
}

# Prohibits overwriting by redirect and use of undefined variables.
set -Cu

# Enable trace, verbose
[ $_xtrace_enable -eq 0 ] || {
  PS4='>(${BASH_SOURCE:-$THIS}:${LINENO:-0})${FUNCNAME:+:$FUNCNAME()}: '
  export PS4
  set -xv
}

# Dry run
[ $_x_dryrun_mode -eq 0 ] || {
  DOT_SSH_XDGCNF="${DOT_SSHCNF_TMP}${DOT_SSH_XDGCNF}"
  DOT_SSHCNF_DIR="${DOT_SSHCNF_TMP}${DOT_SSHCNF_DIR}"
}

# Set trap
trap "_cleanup" SIGTERM SIGHUP SIGINT SIGQUIT
trap "_cleanup" EXIT

# Checking install base
[ -d "${DOT_SSH_XDGCNF}" ] || {
  mkdir -p "${DOT_SSH_XDGCNF}" &&
  chmod 0755 "${DOT_SSH_XDGCNF}"
} 2>/dev/null

# Install or update
if [ ! -d "${DOT_SSHCNF_XDG}/.git" ]
then

  echo "Git Clone from '${DOT_SSHCNF_URL}'."

  # Install
  ( [ -d "${DOT_SSHCNF_XDG}" ] && {
      mv -f "${DOT_SSHCNF_XDG}" \
            "${DOT_SSHCNF_XDG}.$(date +'%Y%m%dT%H%M%S')"
    } || :
    cd "${DOT_SSH_XDGCNF}" && {
      ${dot_sshcnf_git} clone "${DOT_SSHCNF_URL}";
    }; )

else

  echo "Git Pull from '${DOT_SSHCNF_URL}'."

  # Update
  ( cd "${DOT_SSHCNF_XDG}" && {
      ${dot_sshcnf_git} stash save "$(date +%'Y%m%dT%H%M%S')";
      ${dot_sshcnf_git} pull;
    }; )

fi

# $HOME/.ssh
[ -d "${DOT_SSHCNF_DIR}" ] || {
  ( mkdir -p "${DOT_SSHCNF_DIR}" &&
    cd "${DOT_SSHCNF_DIR}" &&
    chmod 0700 .; )
} 2>/dev/null

# Setup
( cd "${DOT_SSHCNF_DIR}" && {

  echo "Pwd '$(pwd)'."

  for sshentry in $(cd "${DOT_SSHCNF_XDG}/ssh"; find . |sort)
  do

    ent_name="${sshentry#*./}"
    fullpath="${DOT_SSHCNF_XDG}/ssh/${ent_name}"
    
    echo "${ent_name}" |
    egrep "^.git" 1>/dev/null 2>&1 &&
    continue || :

    if [ -d "${fullpath}" ]
    then

      [ -d "./${ent_name}" ] || {
        mkdir -p "./${ent_name}" &&
        chmod 0700 "./${ent_name}" &&
        echo "Mkdir '${DOT_SSHCNF_DIR}/${ent_name}'." || :
      } 2>/dev/null

    else
    
      realpath=$(readlink "./${ent_name}" 2>/dev/null || :)

      filemode=$(
        case "${ent_name}" in
        *.*sh) echo 0700 ;;
        *)     echo 0600 ;;
        esac 2>/dev/null; )
      
      [ "${fullpath}" = "${realpath}" ] || {
        printf "Symlink '%s' to '%s': " "${fullpath}" "${HOME}/.ssh/${ent_name}"
        ln -sf "${fullpath}" "./${ent_name}" 2>/dev/null &&
        chmod "${filemode}" "./${ent_name}" 2>/dev/null &&
        echo "done." ||
        echo "fail."
      }

    fi

  done

}; )

# Finish installation
echo
echo "Done."

# End
exit 0
