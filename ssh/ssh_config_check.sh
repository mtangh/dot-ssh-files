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
# ssh_config_cat.sh
[ -x "${CDIR}/ssh_config_cat.sh" ] || {
  echo "${NAME}: ERROR: 'ssh_config_cat.sh': command not found." 1>&2
  exit 1; }
# Run
exec "${CDIR}/ssh_config_cat.sh" check "$@"
# End
exit $?
