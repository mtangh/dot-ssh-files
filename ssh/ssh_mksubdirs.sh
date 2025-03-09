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
# Mkdir
for ssh_subdir in $(
  : && {
    cat "${ssh_cnfdir}"/config
    cat "${ssh_cnfdir}"/default.conf
    cat "${ssh_cnfdir}"/config.d/*
  } 2>/dev/null |
  grep -Ev '^[[:space:]]*#' |
  grep -E '/[^/]+/' |awk '{print($2);}' |
  grep -Ev '^/dev/null' |
  sort -u |xargs -n1 dirname |sort -u; )
do
  ssh_subdir="$(eval echo "${ssh_subdir}")"
  [ -n "${ssh_subdir:-}" ] ||
    continue
  [ "${ssh_subdir}" != "${ssh_cnfdir}" ] ||
    continue
  [ -e "${ssh_subdir:-X}" ] || {
    echo "Mkdir: ${ssh_subdir:-}" &&
    mkdir -p "${ssh_subdir:-}"; }
done
# End
exit $?
