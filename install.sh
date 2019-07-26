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

# dot-ssh-files name
DOT_SSHCNF_PRJ="${DOT_SSHCNF_URL##*/}"
DOT_SSHCNF_PRJ="${DOT_SSHCNF_PRJ%.git*}"

# XDG Config Dir
DOT_SSH_XDGCNF="${XDG_CONFIG_HOME:-$HOME/.config}"

# Install Dir
DOT_SSHCNF_XDG="${DOT_SSHCNF_XDG:-$DOT_SSH_XDGCNF/$DOT_SSHCNF_PRJ}"

# SSH Config Dir
DOT_SSHCNF_DIR="${DOT_SSHCNF_DIR:-$HOME/.ssh}"

# Temp die
DOT_SSHCNF_TMP="${TMPDIR:-/tmp}/.${BASE}.$$"

# Ssh
dot_sshcnf_ssh="$(type -P ssh)"

# Git
dot_sshcnf_git="$(type -P git)"

# Flags
_inc_directive=0
_x_dryrun_mode=0
_xtrace_enable=0

# Check
[ -x "${dot_sshcnf_ssh}" ] || {
  _echo "ERROR: ssh '${dot_sshcnf_ssh}': Command not found." 1>&2
  exit 127
}
[ -x "${dot_sshcnf_git}" ] || {
  _echo "ERROR: git '${dot_sshcnf_git}': Command not found." 1>&2
  exit 127
}

# Debug
case "${DEBUG:-NO}" in
0|[Nn][Oo]|[Oo][Ff][Ff])
  ;;
*)
  _x_dryrun_mode=1
  _xtrace_enable=1
  ;;
esac || :

# Echo
_echo() {
  echo "$THIS: $@"
  return 0
}

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
    _echo "ERROR: Illegal option '${1}'." 1>&2; exit 22
    ;;
  *)
    ;;
  esac
  shift
done

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

# Temp dir.
[ -d "${DOT_SSHCNF_TMP}" ] || {
  mkdir -p "${DOT_SSHCNF_TMP}" &&
  chmod 0700 "${DOT_SSHCNT_TMP}"
} 1>/dev/null 2>&1

# Set trap
trap "_cleanup" SIGTERM SIGHUP SIGINT SIGQUIT
trap "_cleanup" EXIT

# ssh version
_echo "SSH-Version: $(${dot_sshcnf_ssh} -V 2>&1)"

# Include ?
_inc_directive=$(
  : && {
    "${dot_sshcnf_ssh}" -oInclude=/dev/null localhost 2>&1 |
    egrep -i 'Bad[ \t]+configuration[ \t]+option:[ \t]+include'
  } 1>/dev/null 2>&1 && echo "0" || echo "1"; )

# Include support ?
if [ $_inc_directive -eq 0 ]
then
  _echo "Your ssh does not support include directive." 1>&2
fi

# Checking install base
[ -d "${DOT_SSH_XDGCNF}" ] || {
  mkdir -p "${DOT_SSH_XDGCNF}" &&
  chmod 0755 "${DOT_SSH_XDGCNF}"
} 2>/dev/null

# Install or update
if [ ! -d "${DOT_SSHCNF_XDG}/.git" ]
then

  _echo "Git clone from '${DOT_SSHCNF_URL}'."

  # Install
  ( [ -d "${DOT_SSHCNF_XDG}" ] && {
      mv -f "${DOT_SSHCNF_XDG}" \
            "${DOT_SSHCNF_XDG}.$(date +'%Y%m%dT%H%M%S')"
    } || :
    cd "${DOT_SSH_XDGCNF}" && {
      ${dot_sshcnf_git} clone "${DOT_SSHCNF_URL}"
    }; )

else

  _echo "Git pull from '${DOT_SSHCNF_URL}'."

  # Update
  ( cd "${DOT_SSHCNF_XDG}" && {
      ${dot_sshcnf_git} stash save "$(date +%'Y%m%dT%H%M%S')";
      ${dot_sshcnf_git} pull;
    }; )

fi &&
[ -d "${DOT_SSHCNF_XDG}" ] && {
  ( cd "${DOT_SSHCNF_XDG}" &&
    ${dot_sshcnf_git} config --get core.filemode |
    egrep -i '^false$' 1>/dev/null 2>&1 || {
      ${dot_sshcnf_git} config core.filemode false &&
      _echo "Git config: repo=${DOT_SSHCNF_PRJ} core.filemode=off."
    }; )
} || exit $?

# $HOME/.ssh
[ -d "${DOT_SSHCNF_DIR}" ] || {
  ( mkdir -p "${DOT_SSHCNF_DIR}" &&
    cd "${DOT_SSHCNF_DIR}" &&
    chmod 0700 .; )
} 2>/dev/null

# Setup
( cd "${DOT_SSHCNF_DIR}" && {

  _echo "Pwd '$(pwd)'."

  for sshentry in $(cd "${DOT_SSHCNF_XDG}/ssh"; find . |sort)
  do

    ent_name="${sshentry#*./}"
    fullpath="${DOT_SSHCNF_XDG}/ssh/${ent_name}"

    [ "${ent_name}" = "." ] &&
    continue || :

    echo "${ent_name}" |
    egrep '(^|^.+/).git(/.+$|/$|$)' 1>/dev/null 2>&1 &&
    continue || :

    if [ -d "${fullpath}" ]
    then

      [ -d "./${ent_name}" ] || {
        mkdir -p "./${ent_name}" &&
        chmod 0700 "./${ent_name}" &&
        _echo "Mkdir '${DOT_SSHCNF_DIR}/${ent_name}'." || :
      } 2>/dev/null

    else

      destname=$(
        case "${ent_name}::${_inc_directive}" in
        config::0)
          echo "${ent_name}.tmpl" ;;
        *)
          echo "${ent_name}" ;;
        esac 2>/dev/null; )

      filemode=$(
        case "${destname}" in
        *.*sh)
          echo 0755 ;;
        *)
          echo 0600 ;;
        esac 2>/dev/null; )

      realpath=$(readlink "./${destname}" 2>/dev/null || :;)

      if [ "${fullpath}" != "${realpath}" ]
      then
        printf "$THIS: Symlink '%s' to '%s' ... " "${fullpath}" "${destname}"
        : && {
          ln -sf "${fullpath}" "./${destname}" 1>/dev/null 2>&1 &&
          chmod "${filemode}" "./${destname}" 1>/dev/null 2>&1
        } && echo "OK." || echo "NG."
      fi

    fi

  done

  if [ $_inc_directive -eq 0 ]
  then
    [ -x "./ssh_config_cat.sh" -a -r "./config.tmpl" ] && {
      ./ssh_config_cat.sh -fconfig.tmpl
    } 1>|"./config" || :
  fi

}; )

# Finish installation
_echo "Done."

# End
exit 0
