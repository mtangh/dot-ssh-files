#!/bin/bash
# shellcheck disable=SC2015,SC2034,SC2120,SC2124,SC2128,SC2166
[ -n "$BASH" ] 1>/dev/null 2>&1 || {
echo "Run it in bash." 1>&2; exit 1; }
THIS="${BASH_SOURCE:-./install.sh}"
NAME="${THIS##*/}"
BASE="${NAME%.*}"
CDIR=$([ -n "${THIS%/*}" ] && cd "${THIS%/*}" &>/dev/null || :; pwd)
# Prohibits overwriting by redirect and use of undefined variables.
set -Cu
# The return value of a pipeline is the value of the last command to
# exit with a non-zero status.
set -o pipefail
# Case insensitive regular expressions.
shopt -s nocasematch
# Path
PATH=/usr/bin:/usr/sbin:/bin:/sbin; export PATH
# Git Project URL
GIT_PROJ_URL="${GIT_PROJ_URL:-https://github.com/mtangh/dot-ssh-files.git}"
# Git Project name
GIT_PROJNAME="${GIT_PROJ_URL##*/}"
GIT_PROJNAME="${GIT_PROJNAME%.git*}"
# Install Prefix
INSTALL_PREFIX="${INSTALL_PREFIX:-}"
# Install Source
INSTALL_SOURCE="${INSTALL_SOURCE:-}"
# Install Workdir
[ -n "${INSTALLWORKDIR:-}" ] ||
INSTALLWORKDIR="$(cd ${TMPDIR:-/tmp} || :;pwd)/${GIT_PROJNAME}.$$"
# Timestamp
INSTALL_TIMEST="$(date +'%Y%m%dT%H%M%S')"
# Flag: Xtrace
X_TRACE_ON=0
# Flag: dry-run
DRY_RUN_ON=0
# Flags
_inc_directive=0
# Function: Stdout
_stdout() {
  local ltag="${1:-$GIT_PROJNAME/$NAME}"
  local line=""
  cat - | while IFS= read -r line
  do
    [[ "${line}" =~ ^${ltag}: ]] ||
    printf "%s: " "${ltag}"; echo "${line}"
  done
  return 0
}
# Function: Echo
_echo() {
  echo "$@" |_stdout
}
# Function: Abort
_abort() {
  local exitcode=1 &>/dev/null
  local messages="$@"
  [[ ${1:-} =~ ^[0-9]+$ ]] && {
    exitcode="${1}"; shift;
  } &>/dev/null
  echo "ERROR: ${messages} (${exitcode:-1})" |_stdout 1>&2
  [ ${exitcode:-1} -le 0 ] || exit ${exitcode:-1}
  return 0
}
# Function: Cleanup
_cleanup() {
  [ -n "${INSTALLWORKDIR}" ] && {
    rm -rf "${INSTALLWORKDIR}" &>/dev/null
  } || :
  return 0
}
# Function: usage
_usage() {
cat <<_USAGE_
Usage: ${GIT_PROJNAME}/${NAME} [OPTIONS]

OPTIONS:

-D, --debug
  Enable debug output.
-n, --dry-run
  Dry run mode

_USAGE_
  return 0
}
# Ssh command
ssh_cmnd="$(type -P ssh)"
[ -z "${ssh_cmnd}" ] && {
  _abort 1 "Command (ssh) not found."; } || :
# Git command
git_cmnd="$(type -P git)"
[ -z "${git_cmnd}" ] && {
  _abort 1 "Command (git) not found."; } || :
# Platform
DOTSSHCNF_OS="${OSTYPE:-}"
# XDG Config Dir
DOTSSHXDGCNF="${XDG_CONFIG_HOME:-$HOME/.config}"
# OS
[ -z "${DOTSSHCNF_OS:-}" ] && {
  DOTSSHCNF_OS=$(uname -s); } || :
if [[ "${DOTSSHCNF_OS:-}" =~ ^darwin ]]
then
  DOTSSHCNF_OS=$(
    if [ -x "/usr/bin/sw_vers" ]
    then DOTSSHCNF_OS=$(/usr/bin/sw_vers -productName)
    else DOTSSHCNF_OS="darwin"
    fi || :
    echo "${DOTSSHCNF_OS// /}"; )
else
  DOTSSHCNF_OS="${DOTSSHCNF_OS%%-*}"
fi &&
[ -n "${DOTSSHCNF_OS:-}" ] && {
  DOTSSHCNF_OS=$(
    echo "${DOTSSHCNF_OS}" |
    tr '[:upper:]' '[:lower:]';); } || :
# SSH Config Dir
INSTALL_PREFIX="${INSTALL_PREFIX:-$HOME/.ssh}"
# Install Source Dir
INSTALL_SOURCE="${INSTALL_SOURCE:-$DOTSSHXDGCNF/$GIT_PROJNAME}"
# Debug
[[ "${DEBUG:-NO}" =~ ^([1-9][0-9]*|YES|ON|TRUE)$ ]] && {
  X_TRACE_ON=1; DRY_RUN_ON=1; } || :
# Parsing command line options
while [ $# -gt 0 ]
do
  case "${1:-}" in
  -D*|-debug*|--debug*)
    X_TRACE_ON=1
    ;;
  -n*|-dry-run*|--dry-run*)
    DRY_RUN_ON=1
    ;;
  -h|-help*|--help*)
    _usage; exit 0
    ;;
  *)
    _abort 22 "Invalid argument, argv='${1:-}'."
    ;;
  esac
  shift
done
# Enable trace, verbose
[ ${X_TRACE_ON:-0} -eq 0 ] || {
  PS4='>(${LINENO:--})${FUNCNAME+:$FUNCNAME()}: '
  export PS4; set -xv; shopt -s extdebug; }
# Dry run
[ ${DRY_RUN_ON:-0} -eq 0 ] || {
  DOTSSHXDGCNF="${INSTALLWORKDIR}${DOTSSHXDGCNF}"
  INSTALL_PREFIX="${INSTALLWORKDIR}${INSTALL_PREFIX}"
  INSTALL_SOURCE="${INSTALLWORKDIR}${INSTALL_SOURCE}"
}
# Temp dir.
[ -d "${INSTALLWORKDIR}" ] || {
  mkdir -p "${INSTALLWORKDIR}" &&
  chmod 0700 "${INSTALLWORKDIR}" || :
} &>/dev/null
# Set trap
: "Trap" && {
  trap "_cleanup" SIGTERM SIGHUP SIGINT SIGQUIT
  trap "_cleanup" EXIT
}
# Print message
cat - <<_MSG_ |_stdout
#
# ${GIT_PROJNAME}/${NAME} Date=${INSTALL_TIMEST}
#
_MSG_
# ssh version
_echo "SSH-Version: $(${ssh_cmnd} -V 2>&1)"
# Include ?
_inc_directive=$(
  : && {
    "${ssh_cmnd}" -oInclude=/dev/null localhost 2>&1 |
    grep -Ei 'Bad[ \t]+configuration[ \t]+option:[ \t]+include'
  } &>/dev/null && echo "0" || echo "1"; )
# Include support ?
if [ ${_inc_directive} -eq 0 ]
then
  _echo "Your ssh does not support include directive." 1>&2
fi
# Checking install base
[ -d "${DOTSSHXDGCNF}" ] || {
  mkdir -p "${DOTSSHXDGCNF}" &&
  chmod 0755 "${DOTSSHXDGCNF}"
} 2>/dev/null
# Install or update
if [ ! -d "${INSTALL_SOURCE}/.git" ]
then
  _echo "Git clone from '${GIT_PROJ_URL}'."
  # Install
  ( [ -d "${INSTALL_SOURCE}" ] && {
      mv -f "${INSTALL_SOURCE}" \
            "${INSTALL_SOURCE}.$(date +'%Y%m%dT%H%M%S')"
    } || :
    cd "${DOTSSHXDGCNF}" && {
      ${git_cmnd} clone "${GIT_PROJ_URL}"
    }; )
else
  _echo "Git pull from '${GIT_PROJ_URL}'."
  # Update
  ( cd "${INSTALL_SOURCE}" && {
      ${git_cmnd} stash save "$(date +%'Y%m%dT%H%M%S')";
      ${git_cmnd} pull;
    }; )
fi &&
[ -d "${INSTALL_SOURCE}" ] && {
  ( cd "${INSTALL_SOURCE}" &&
    ${git_cmnd} config --get core.filemode |
    grep -Ei '^false$' &>/dev/null || {
      ${git_cmnd} config core.filemode false &&
      _echo "Git config: repo=${GIT_PROJNAME} core.filemode=off."
    }; )
} || exit $?
# $HOME/.ssh
[ -d "${INSTALL_PREFIX}" ] || {
  ( mkdir -p "${INSTALL_PREFIX}" &&
    cd "${INSTALL_PREFIX}" &&
    chmod 0700 .; )
} 2>/dev/null
# Setup
( cd "${INSTALL_PREFIX}" && {

  _echo "OS-Type: [${DOTSSHCNF_OS}]"
  _echo "Pwd: [$(pwd)]"

  for sshentry in $(
    cd "${INSTALL_SOURCE}/ssh" && {
      find . ! -name "default.conf.*" |
      sort
    } 2>/dev/null; )
  do

    ent_name="${sshentry#*./}"
    fullpath="${INSTALL_SOURCE}/ssh/${ent_name}"
    destname="${ent_name}"
    filemode="0600"
    use_link=1

    [ "${ent_name}" = "." ] &&
    continue || :

    echo "${ent_name}" |
    grep -Ei '(^|^.+/).git.*$' &>/dev/null &&
    continue || :

    if [ -d "${fullpath}" ]
    then
      _echo "IsDir '${ent_name}' [${fullpath}]."
      [ -d "./${ent_name}" ] || {
        mkdir -p "./${ent_name}" && chmod 0700 "./${ent_name}" &&
        _echo "Mkdir '${INSTALL_PREFIX}/${ent_name}'." ||
        _echo "Failed Mkdir '${INSTALL_PREFIX}/${ent_name}'."
      } 2>/dev/null || :
      continue
    fi

    eval_ent="${ent_name}::${_inc_directive:-0}"

    if [[ "${eval_ent}" =~ ^config::0$ ]]
    then
      destname="${ent_name}.tmpl"
    elif [[ "${eval_ent}" =~ ^default[.]conf:: ]]
    then
      [ -s "${fullpath}.${DOTSSHCNF_OS}" ] && {
        ent_name="${ent_name}.${DOTSSHCNF_OS}"
        fullpath="${INSTALL_SOURCE}/ssh/${ent_name}"
      } || :
    elif [[ "${eval_ent}" =~ ^config[.]d/.+[.].+::.*$ ]]
    then
      use_link=0
    elif [[ "${eval_ent}" =~ ^.+[.].*sh::.*$ ]]
    then
      filemode="0755"
    else
      filemode="0644"
    fi

    if [ ! -e "./${destname}" -a -e "./${destname}.off" ]
    then
      destname="${destname}.off"
    elif [ ! -e "./${destname}" -a -e "./${destname}.disabled" ]
    then
      destname="${destname}.disabled"
    fi

    if [ ${use_link} -ne 0 ] &&
       [ "${fullpath}" != "$(readlink "./${destname}" 2>/dev/null || :;)" ]
    then
      : && {
        printf "Symlink '%s' to '%s' ... " "${fullpath}" "${destname}" &&
        ln -sf "${fullpath}" "./${destname}" && chmod "${filemode}" "./${destname}" &&
        echo "OK." || echo "NG."
      } 2>/dev/null |_stdout
    elif [ ${use_link} -eq 0 ] &&
         ! diff "${fullpath}" "./${destname}" &>/dev/null
    then
      : && {
        printf "Copy '%s' to '%s' ... " "${fullpath}" "${destname}" &&
        cp -pf "${fullpath}" "./${destname}" && chmod "${filemode}" "./${destname}" &&
        echo "OK." || echo "NG."
      } 2>/dev/null |_stdout
    else
      _echo "NOOP '%s'('%s')." "${fullpath}" "${destname}"
    fi

  done

  if [ ${_inc_directive:-0} -eq 0 ]
  then
    [ -x "./ssh_config_cat.sh" -a -r "./config.tmpl" ] && {
      ./ssh_config_cat.sh -fconfig.tmpl
    } 1>| "./config" || :
  fi

}; )
# Finish installation
_echo "Done."
# End
exit 0
