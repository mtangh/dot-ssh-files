#!/bin/bash
[ -n "$BASH" ] 1>/dev/null 2>&1 || {
echo "Run it in bash." 1>&2; exit 1; }
THIS="${BASH_SOURCE}"
NAME="${THIS##*/}"
NAME="${NAME:-install.sh}"
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
# dot-ssh-files URL
GIT_PROJ_URL="${GIT_PROJ_URL:-https://github.com/mtangh/dot-ssh-files.git}"
# dot-ssh-files name
GIT_PROJNAME="${GIT_PROJ_URL##*/}"
GIT_PROJNAME="${GIT_PROJNAME%.git*}"
# SSH Config Dir
DOTSSHCNFDIR="${DOTSSHCNFDIR:-$HOME/.ssh}"
# Platform
DOTSSHCNF_OS="${OSTYPE:-}"
# XDG Config Dir
DOTSSHXDGCNF="${XDG_CONFIG_HOME:-$HOME/.config}"
# Install Dir
DOTSSHCNFXDG="${DOTSSHCNFXDG:-$DOTSSHXDGCNF/$GIT_PROJNAME}"
# Temp die
DOTSSHCNFTMP="${TMPDIR:-/tmp}/.${GIT_PROJNAME}.$$"
# Ssh
dot_sshcnf_ssh="$(type -P ssh)"
# Git
dot_sshcnf_git="$(type -P git)"
# Flags
_inc_directive=0
_x_dryrun_mode=0
_xtrace_enable=0
# OS
[ -z "${DOTSSHCNF_OS:-}" ] && {
  DOTSSHCNF_OS=$(uname -s)
} || :
case "${DOTSSHCNF_OS:-}" in
darwin*)
  DOTSSHCNF_OS=$(
    if [ -x "/usr/bin/sw_vers" ]
    then DOTSSHCNF_OS=$(/usr/bin/sw_vers -productName)
    else DOTSSHCNF_OS="darwin"
    fi || :
    echo "${DOTSSHCNF_OS// /}"; )
    ;;
*-*)
  DOTSSHCNF_OS="${DOTSSHCNF_OS%%-*}"
  ;;
esac
[ -n "${DOTSSHCNF_OS:-}" ] && {
  DOTSSHCNF_OS=$(
    echo "${DOTSSHCNF_OS}"|
    tr '[:upper:]' '[:lower:]'; )
} || :
# Debug
case "${DEBUG:-NO}" in
0|[Nn][Oo]|[Oo][Ff][Ff])
  ;;
*)
  _x_dryrun_mode=1
  _xtrace_enable=1
  ;;
esac || :
# Function: Stdout
_stdout() {
  local ltag="${1:-$NAME}"
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
  [ -n "${DOTSSHCNFTMP}" ] && {
    rm -rf "${DOTSSHCNFTMP}" &>/dev/null
  } || :
  return 0
}
# Check
[ -x "${dot_sshcnf_ssh}" ] ||
_abort 1 "ssh '${dot_sshcnf_ssh:-?}': Command not found."
[ -x "${dot_sshcnf_git}" ] ||
_abort 1 "git '${dot_sshcnf_git:-?}': Command not found."
# Parsing command line options
while [ $# -gt 0 ]
do
  case "${1:-}" in
  -D*|-debug*|--debug*)
    _xtrace_enable=1
    ;;
  -n*|-dry-run*|--dry-run*)
    _x_dryrun_mode=1
    ;;
  *)
    _abort 22 "Invalid argument, arg='${1:-}'."
    ;;
  esac
  shift
done
# Enable trace, verbose
[ ${_xtrace_enable:-0} -eq 0 ] || {
  PS4='>(${NAME}:${LINENO:-0})${FUNCNAME:+:$FUNCNAME()}: '
  export PS4; set -xv; }
# Dry run
[ ${_x_dryrun_mode:-0} -eq 0 ] || {
  DOTSSHXDGCNF="${DOTSSHCNFTMP}${DOTSSHXDGCNF}"
  DOTSSHCNFXDG="${DOTSSHCNFTMP}${DOTSSHCNFXDG}"
  DOTSSHCNFDIR="${DOTSSHCNFTMP}${DOTSSHCNFDIR}"
}
# Temp dir.
[ -d "${DOTSSHCNFTMP}" ] || {
  mkdir -p "${DOTSSHCNFTMP}" &&
  chmod 0700 "${DOTSSHCNFTMP}" || :
} &>/dev/null
# Set trap
: "Trap" && {
  trap "_cleanup" SIGTERM SIGHUP SIGINT SIGQUIT
  trap "_cleanup" EXIT
}
# ssh version
_echo "SSH-Version: $(${dot_sshcnf_ssh} -V 2>&1)"
# Include ?
_inc_directive=$(
  : && {
    "${dot_sshcnf_ssh}" -oInclude=/dev/null localhost 2>&1 |
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
if [ ! -d "${DOTSSHCNFXDG}/.git" ]
then
  _echo "Git clone from '${GIT_PROJ_URL}'."
  # Install
  ( [ -d "${DOTSSHCNFXDG}" ] && {
      mv -f "${DOTSSHCNFXDG}" \
            "${DOTSSHCNFXDG}.$(date +'%Y%m%dT%H%M%S')"
    } || :
    cd "${DOTSSHXDGCNF}" && {
      ${dot_sshcnf_git} clone "${GIT_PROJ_URL}"
    }; )
else
  _echo "Git pull from '${GIT_PROJ_URL}'."
  # Update
  ( cd "${DOTSSHCNFXDG}" && {
      ${dot_sshcnf_git} stash save "$(date +%'Y%m%dT%H%M%S')";
      ${dot_sshcnf_git} pull;
    }; )
fi &&
[ -d "${DOTSSHCNFXDG}" ] && {
  ( cd "${DOTSSHCNFXDG}" &&
    ${dot_sshcnf_git} config --get core.filemode |
    grep -Ei '^false$' &>/dev/null || {
      ${dot_sshcnf_git} config core.filemode false &&
      _echo "Git config: repo=${GIT_PROJNAME} core.filemode=off."
    }; )
} || exit $?
# $HOME/.ssh
[ -d "${DOTSSHCNFDIR}" ] || {
  ( mkdir -p "${DOTSSHCNFDIR}" &&
    cd "${DOTSSHCNFDIR}" &&
    chmod 0700 .; )
} 2>/dev/null
# Setup
( cd "${DOTSSHCNFDIR}" && {

  _echo "OS-Type: [${DOTSSHCNF_OS}]"
  _echo "Pwd: [$(pwd)]"

  for sshentry in $(
    cd "${DOTSSHCNFXDG}/ssh" && {
      find . ! -name "default.conf.*" |
      sort
    } 2>/dev/null; )
  do

    ent_name="${sshentry#*./}"
    fullpath="${DOTSSHCNFXDG}/ssh/${ent_name}"
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

      [ -d "./${ent_name}" ] || {
        mkdir -p "./${ent_name}" &&
        chmod 0700 "./${ent_name}" &&
        _echo "Mkdir '${DOTSSHCNFDIR}/${ent_name}'."
      } 2>/dev/null || :

      continue

    fi

    case "${ent_name}::${_inc_directive}" in
    config::0)
      destname="${ent_name}.tmpl"
      ;;
    default.conf::*)
      [ -s "${fullpath}.${DOTSSHCNF_OS}" ] && {
        ent_name="${ent_name}.${DOTSSHCNF_OS}"
        fullpath="${DOTSSHCNFXDG}/ssh/${ent_name}"
      } || :
      ;;
    config.d/*.*::*)
      use_link=0
      ;;
    *.*sh::*)
      filemode="0755"
      ;;
    *)
      filemode="0644"
      ;;
    esac

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

      printf "${NAME}: Symlink '%s' to '%s' ... " "${fullpath}" "${destname}" && {
        ln -sf "${fullpath}" "./${destname}" &&
        chmod "${filemode}" "./${destname}"
      } &>/dev/null &&
      echo "OK." || echo "NG."

    elif [ ${use_link} -eq 0 ] &&
         ! diff "${fullpath}" "./${destname}" &>/dev/null
    then

      printf "${NAME}: Copy '%s' to '%s' ... " "${fullpath}" "${destname}" && {
        cp -pf "${fullpath}" "./${destname}" &&
        chmod "${filemode}" "./${destname}"
      } &>/dev/null &&
      echo "OK." || echo "NG."

    else
      _echo "NOOP '%s'('%s')." "${fullpath}" "${destname}"
    fi

  done

  if [ ${_inc_directive:-0} -eq 0 ]
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
