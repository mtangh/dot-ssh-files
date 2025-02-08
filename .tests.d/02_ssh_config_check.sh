#!/bin/bash
THIS="${BASH_SOURCE##*/}"
CDIR=$([ -n "${BASH_SOURCE%/*}" ] && cd "${BASH_SOURCE%/*}" &>/dev/null; pwd)

# Run tests
echo "[${tests_name}] ssh_config_check.sh" && {

  bash -n "$HOME/.ssh/ssh_config_cat.sh" &&
  bash -x "$HOME/.ssh/ssh_config_cat.sh" |
  grep -Ei '^[[:space:]]*(LogLevel[[:space:]]+VERBOSE|CheckHostIP[[:space:]]+no)[[:space:]]*$'

} &&
echo "[${tests_name}] DONE."

# End
exit $?
