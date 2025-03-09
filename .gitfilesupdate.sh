#!/bin/bash
[ -n "$BASH" ] 1>/dev/null 2>&1 || {
echo "Run it in bash." 1>&2; exit 1; }
THIS="${BASH_SOURCE:-./gitfilesupdate.sh}"
NAME="${THIS##*/}"
BASE="${NAME%.*}"
CDIR=$([ -n "${THIS%/*}" ] && cd "${THIS%/*}" &>/dev/null || :; pwd)
# Prohibits overwriting by redirect and use of undefined variables.
set -Cu
# The return value of a pipeline is the value of the last command to
# exit with a non-zero status.
set -o pipefail
# Install Shell
installsh="${DOT_GIT_FILES_INSTALL_SH:-}"
[ -z "${installsh}" -a -s "${CDIR}/update.sh" ] &&
installsh="${CDIR}/update.sh" || :
[ -z "${installsh}" -a ! -s "${CDIR}/update.sh" ] && {
installsh="https://raw.githubusercontent.com"
installsh="${installsh}/mtangh/dot-git-files"
installsh="${installsh}/master/update.sh"; } || :
# Shell opts
shellopts="-s --"
[ -n "${SHELLOPTS:-}" ] &&
[[ ${SHELLOPTS:-} =~ (^|:)xtrace(:|$) ]] &&
shellopts="-x ${shellopts}"
# Get Command
scriptget=""
case "${installsh:-}" in
http*)
  [ -z "${scriptget}" -a -n "$(type -P curl 2>/dev/null)" ] &&
  scriptget="$(type -P curl 2>/dev/null) -sL" || :
  [ -z "${scriptget}" -a  -n "$(type -P wget 2>/dev/null)" ] &&
  scriptget="$(type -P wget 2>/dev/null) -qO -" || :
  # Run
  [ -n "${scriptget}" ] &&
  ${scriptget} "${installsh}" 2>/dev/null |${BASH} ${shellopts} "$@"
  ;;
*)
  ${BASH} ${shellopts##*-s --} "${installsh}" "$@" 2>/dev/null
  ;;
esac
# End
exit $?
