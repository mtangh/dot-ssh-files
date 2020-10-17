#!/bin/bash
THIS="${BASH_SOURCE##*/}"
NAME="${THIS%.*}"
CDIR=$([ -n "${BASH_SOURCE%/*}" ] && cd "${BASH_SOURCE%/*}" 2>/dev/null; pwd)
# Prohibits overwriting by redirect and use of undefined variables.
set -Cu
# Install Shell
installsh="https://raw.githubusercontent.com"
installsh="${installsh}/mtangh/dot-git-files"
installsh="${installsh}/master/update.sh"
# Shell opts
shellopts="-s --"
[ -n "${SHELLOPTS}" ] && [[ ${SHELLOPTS} =~ (^|:)xtrace(:|$) ]] &&
shellopts="-x ${shellopts}"
# Get Command
scriptget=""
[ -z "${scriptget}" -a -n "$(type -P curl 2>/dev/null)" ] &&
scriptget="$(type -P curl 2>/dev/null) -sL" || :
[ -z "${scriptget}" -a  -n "$(type -P wget 2>/dev/null)" ] &&
scriptget="$(type -P wget 2>/dev/null) -qO -" || :
# Run
[ -n "${scriptget}" ] &&
${scriptget} "${installsh}" 2>/dev/null |/bin/bash ${shellopts} "$@"
# End
exit $?
