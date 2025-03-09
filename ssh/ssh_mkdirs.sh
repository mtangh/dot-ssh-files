#!/bin/bash
[ "$0" = "$BASH_SOURCE" ] 1>/dev/null 2>&1 || {
echo "Run it directory." 1>&2; exit 1; }
THIS="${BASH_SOURCE}"
NAME="${THIS##*/}"
BASE="${NAME%.*}"
CDIR=$([ -n "${THIS%/*}" ] && cd "${THIS%/*}" &>/dev/null || :; pwd)
# Prohibits overwriting by redirect and use of undefined variables.
set -Cu
# The return value of a pipeline is the value of the last command to
# exit with a non-zero status.
set -o pipefail
# ssh config dir
ssh_cnfdir="${HOME}/.ssh"
# Control Path
sshctrldir="$(eval echo "$(
  : && {
    cat "${ssh_cnfdir}"/config "${ssh_cnfdir}"/default.conf
    cat "${ssh_cnfdir}"/config.d/*
  } 2>/dev/null |
  grep -h "ControlPath " 2>/dev/null |
  grep -Ev '^[[:space:]]*#' |awk '{print($2);}' |
  grep -E '/[^/]+/' |head -n1)")"
sshctrldir="${sshctrldir%/*}"
# Mkdir
[ -z "${sshctrldir:-}" ] ||
[ -d "${sshctrldir:-X}" ] || {
  echo "Mkdir: ${sshctrldir:-}" &&
  mkdir -p "${sshctrldir:-}"
}
# End
exit $?
