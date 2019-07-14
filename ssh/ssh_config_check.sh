#!/bin/bash
THIS="${0##*/}"
CDIR=$([ -n "${0%/*}" ] && cd "${0%/*}" 2>/dev/null; pwd)
# Name
THIS="${THIS:-ssh_config_check.sh}"
BASE="${THIS%.*}"

# Vars
ssh_config=""
ssh_cnfdir=""
ssh_option="-Gv"
ssh_retval=0

# Flags
_xtrace_on=0
silentmode=0

# Options
while [ $# -gt 0 ]
do
  case "$1" in
  -f*)
    if [ -n "${1##*-f}" ]
    then ssh_config="${1##*-f}"
    else ssh_config="${2}"; shift
    fi
    ;;
  -D*|-debug*|--debug*)
    _xtrace_on=1
    ;;
  -s|-silent|--silent)
    silentmode=1
    _xtrace_on=0
    ;;
  -h|-help*|--help*)
    cat <<_USAGE_
Usage: $THIS [-f /path/to/ssh_config]

_USAGE_
    exit 1
    ;;
  *)
    ;;
  esac
  shift
done

# No unbound vars
set -Cu

# Enable trace, verbose
[ $_xtrace_on -eq 0 ] || {
  PS4='>(${BASH_SOURCE:-$THIS}:${LINENO:-0})${FUNCNAME:+:$FUNCNAME()}: '
  export PS4
  set -xv
}

# Option 'G' support ?
: && {
  ssh $ssh_option localhost 2>&1 |
  egrep -i '(unknown|illegal)[ \t]+option[ \t]+--[ \t]+G'
} 1>/dev/null 2>&1 && {
  cat <<_MSG_
$THIS: ERROR: option 'G' not supported.
_MSG_
  exit 127
} || :

# SSH config
[ -n "${ssh_config}" ] || {
  ssh_config="${HOME}/.ssh/config"
}
[ -r "${ssh_config}" ] || {
  cat <<_MSG_
$THIS: ERROR: '${ssh_config}' no such file or directory.
_MSG_
  exit 1
}

# silent ?
if [ $silentmode -ne 0 ]
then exec 1>/dev/null 2>&1
fi

# ssh_config check
: && {
  ssh $ssh_option -F "${ssh_config}" localhost
  ssh_retval=$?
} 2>&1

# End
exit $ssh_retval
