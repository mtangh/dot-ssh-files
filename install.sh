#!/bin/bash
THIS="${0##*/}"
CDIR=$([ -n "${0%/*}" ] && cd "${0%/*}" 2>/dev/null; pwd)

# Name
THIS="${THIS:-install.sh}"
BASE="${THIS%%.*}"

# Path
PARH=/usr/bin:/bin; export PATH

# dot-ssh-files URL
DOT_SSHCNF_URL="${DOT_SSHCNF_URL:-https://github.com/mtangh/dot-ssh-files.git}"

# Platform
DOT_SSHCONF_OS=$(uname -s|tr '[A-Z]' '[a-z]')

# XDG Config Dir
DOT_SSHCNF_XDG="${HOME}/.config"

# Install Dir
DOT_SSHCNF_DIR="${DOT_SSHCNF_XDG}/dot-ssh-files"

# Git
dot_sshcnf_git="$(type -P git)"

# Flags
_dotgot_dbgrun=0

# Parsing command line options
while [ $# -gt 0 ]
do
  case "$1" in
  -D*|--debug*)
    _dotgot_dbgrun=1
    ;;
  *)
    ;;
  esac
  shift
done

# Check
[ -x "${dot_sshcnf_git}" ] || {
  echo "$THIS: ERROR: '${dot_sshcnf_git}': Command not found." 1>&2
  exit 11
}

# Prohibits overwriting by redirect and use of undefined variables.
set -Cu

# Enable trace, verbose
[ $_dotgot_dbgrun -eq 0 ] || {
  PS4='>(${BASH_SOURCE:-$THIS}:${LINENO:-0})${FUNCNAME:+:$FUNCNAME()}: '
  export PS4
  set -xv
}

# Checking install base
[ -d "${DOT_SSHCNF_XDG}" ] || {
  mkdir -p "${DOT_SSHCNF_XDG}" &&
  chmod 0755 "${DOT_SSHCNF_XDG}"
} 2>/dev/null

# Install or update
if [ ! -d "${DOT_SSHCNF_DIR}/.git" ]
then

  echo "Git Clone from '${DOT_SSHCNF_URL}'."

  # Install
  ( [ -d "${DOT_SSHCNF_DIR}" ] && {
      mv -f "${DOT_SSHCNF_DIR}" \
            "${DOT_SSHCNF_DIR}.$(date +'%Y%m%dT%H%M%S')"
    } || :
    cd "${DOT_SSHCNF_XDG}" && {
      ${dot_sshcnf_git} clone "${DOT_SSHCNF_URL}";
    }; )

else

  echo "Git Pull from '${DOT_SSHCNF_URL}'."

  # Update
  ( cd "${DOT_SSHCNF_DIR}" && {
      ${dot_sshcnf_git} stash save "$(date +%'Y%m%dT%H%M%S')";
      ${dot_sshcnf_git} pull;
    }; )

fi

# $HOME/.ssh
[ -d "${HOME}/.ssh" ] || {
  ( mkdir -p "${HOME}/.ssh" &&
    cd "${HOME}/.ssh" &&
    chmod 0700 .; )
} 2>/dev/null

# Setup
( cd "${HOME}/.ssh" && {

  echo "Pwd '$(pwd)'."

  for sshentry in $(
    cd "${DOT_SSHCNF_DIR}/ssh"; find . |sort)
  do

    ent_name="${sshentry#*./}"
    fullpath="${DOT_SSHCNF_DIR}/ssh/${ent_name}"

    if [ -d "${fullpath}" ]
    then

      [ -d "./${ent_name}" ] || {
        mkdir -p "./${ent_name}" &&
        chmod 0700 "./${ent_name}" &&
        echo "Mkdir '${HOME}/.ssh/${ent_name}'." || :
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
