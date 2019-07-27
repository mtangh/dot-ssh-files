#!/bin/bash
THIS="${0##*/}"
CDIR=$([ -n "${0%/*}" ] && cd "${0%/*}" 2>/dev/null; pwd)
# Name
THIS="${THIS:-ssh_config_update.sh}"
BASE="${THIS%.*}"
# ssh_config_cat.sh
[ -x "${CDIR}/ssh_config_cat.sh" ] || {
  echo "$THIS: ERROR: 'ssh_config_cat.sh': command not found." 1>&2
  exit 1; }
# Run
exec "${CDIR}/ssh_config_cat.sh" update "$@"
# End
exit $?
