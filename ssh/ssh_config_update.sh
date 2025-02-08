#!/bin/bash
[ "$0" = "$BASH_SOURCE" ] &>/dev/null || {
echo "Run it directly" 1>&2; exit 1; }
THIS="${BASH_SOURCE}"
NAME="${THIS##*/}"
CDIR=$([ -n "${THIS%/*}" ] && cd "${THIS%/*}" &>/dev/null; pwd)
# Name
NAME="${NAME:-ssh_config_update.sh}"
BASE="${NAME%.*}"
# Prohibits overwriting by redirect and use of undefined variables.
set -Cu
# ssh_config_cat.sh
[ -x "${CDIR}/ssh_config_cat.sh" ] || {
  echo "${NAME}: ERROR: 'ssh_config_cat.sh': command not found." 1>&2
  exit 1; }
# Run
exec "${CDIR}/ssh_config_cat.sh" update "$@"
# End
exit $?
