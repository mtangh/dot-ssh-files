#!/bin/bash
THIS="${BASH_SOURCE##*/}"
NAME="${THIS%.*}"
CDIR=$([ -n "${BASH_SOURCE%/*}" ] && cd "${BASH_SOURCE%/*}" 2>/dev/null; pwd)
# Prohibits overwriting by redirect and use of undefined variables.
set -Cu
# Update Shell
update_sh="https://raw.githubusercontent.com"
update_sh="${update_sh}/mtangh/dot-git-files"
update_sh="${update_sh}/master/update.sh"
# Shell opts
shellopts="-s --"
[ -n "${SHELLOPTS}" ] &&
[[ ${SHELLOPTS} =~ (^|:)xtrace(:|$) ]] &&
shellopts="-x ${shellopts}"
# Get Command
scriptget=""
[ -z "${scriptget}" ] &&
[ -n "$(type -P curl 2>/dev/null)" ] &&
scriptget="$(type -P curl 2>/dev/null) -sL"
[ -z "${scriptget}" ] &&
[ -n "$(type -P wget 2>/dev/null)" ] &&
scriptget="$(type -P wget 2>/dev/null) -qO -"
# Run
${scriptget} "${update_sh}" 2>/dev/null |/bin/bash $shellopts "$@"
# End
exit $?
