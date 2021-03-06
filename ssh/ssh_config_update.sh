#!/bin/bash
THIS="${BASH_SOURCE##*/}"
NAME="${THIS%.*}"
CDIR=$([ -n "${BASH_SOURCE%/*}" ] && cd "${BASH_SOURCE%/*}" &>/dev/null; pwd)
# Prohibits overwriting by redirect and use of undefined variables.
set -Cu
# ssh_config_cat.sh
[ -x "${CDIR}/ssh_config_cat.sh" ] || {
  echo "${THIS}: ERROR: 'ssh_config_cat.sh': command not found." 1>&2
  exit 1; }
# Run
exec "${CDIR}/ssh_config_cat.sh" update "$@"
# End
exit $?
