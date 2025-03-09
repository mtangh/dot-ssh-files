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
# Base directories.
gkbasedirs=""
# Tag file
gk_tagname="${BASE}"
# Flags
_rebuild=0
_cleanup=0
_verbose=0
_quietly=0
_dry_run=0
_debug_f=0
# function: Usage
usage() {
  local exitstat="${1:-1}"
cat - <<_USAGE_ 2/dev/null
Usage: ${NAME} [OPTION] [dir...]

OPTION:
-R,--rebuild
  Delete all gitkeep and rebuild.
-d,--dry-run
  Enable dry-run mode.
-v,--verbose
  Verbose print.

_USAGE_
  exit ${exitstat:-0}
}
# function: dir list
_get_dir_list() {
  local _dirpath=""
  while read _dirpath
  do
    [[ ${_dirpath} =~ ^$ ]] ||
    [[ ${_dirpath} =~ /$ ]] && {
      _dirpath="${_dirpath%/}"
    } 2>/dev/null || :
    echo "${_dirpath}"
  done < <(
    printf "%b" "${gkbasedirs}" 2>/dev/null |
    sort -u 2>/dev/null; ) || :
  return $?
}
# function: Echo
_echo() {
  local messages="$@"
  [ ${_quietly:-0} -eq 0 ] && {
    echo "${BASE}: ${messages}"
  } 2>/dev/null || :
  return 0
}
# function: Verbose
_verbose() {
  [ ${_verbose:-0} -ne 0 ] && {
    _echo "$@";
  } 2>/dev/null || :
  return 0
}

# Options
while [ $# -gt 0 ]
do
  case "${1:-}" in
  -t*)
    if [ -n "${1#*-t}" ]
    then gk_tagname="${1#*-t}"
    else gk_tagname="${2:-}"; shift
    fi
    ;;
  -R|--rebuild) _rebuild=1; _cleanup=1 ;;
  -c|--clean)   _rebuild=0; _cleanup=1 ;;
  -D|--debug)   _debug_f=1; _quietly=0 ;;
  -d|--dry-run) _dry_run=1; _quietly=0 ;;
  -v|--verbose) _verbose=1; _quietly=0 ;;
  -q|--quiet)   _verbose=0; _quietly=1 ;;
  -h|--help)    usage 0 ;;
  -*)           usage 1 ;;
  *)
    if [ -d "${1:-}" ]
    then
      # Base dir
      gkbasedirs="${gkbasedirs}${1:-}\n"
    else
      echo "${NAME}: '${1:-}': no such file or directory." 1>&2
      exit 2
    fi
    ;;
  esac
  shift
done

# Enable trace, verbose
[ ${_debug_f:-0} -eq 0 ] || {
  PS4='>(${BASH_SOURCE:-$THIS}:${LINENO:-0})${FUNCNAME:+:$FUNCNAME()}: ';
  export PS4
  set -xv
  _dry_run=1
}

# Set default '.' (if empty)
gkbasedirs="${gkbasedirs:-.\n}"
# Tag name
[ -z "${gk_tagname}" ] ||
  gk_tagname="${BASE}"
[[ "${gk_tagname}" =~ ^[.].+ ]] &>/dev/null ||
  gk_tagname=".${gk_tagname}"

# Work
gk_base_dir=""
gk_keep_dir=""

# Cleanup
[ ${_cleanup:-0} -ne 0 ] && {
  # find cmd
  _findcmd=$(
    [ ${_dry_run:-0} -eq 0 ] && echo "rm -f"
    [ ${_dry_run:-0} -eq 0 ] || echo "echo"; )
  # Remove gitkeep
  while read gk_base_dir
  do
    # Print
    _echo "Cleanup: '${gk_base_dir}'."
    # Find 'gitkeep' file under the gk_base_dir and remove it.
    while read _printent
    do
      _verbose "Cleanup: '${_printent}'."
    done < <(
      find "${gk_base_dir}" \
        -name "${gk_tagname}" -a -type f \
        -print -exec ${_findcmd} {} \; ;
      ) 2>/dev/null
  done < <(_get_dir_list)
  # Rebuild ?
  [ ${_rebuild:-0} -eq 0 ] && {
    exit 0; } || :
} || : # [ ${_cleanup:-0} -ne 0 ]

# Process dirs
while read gk_base_dir
do
  # print
  _echo "Gitkeep directory '${gk_base_dir}'."
  # Each empty dirs
  while read gk_keep_dir
  do
    # print
    _verbose "#1 Check dir '${gk_keep_dir}'"
    # Ignore
    [[ "${gk_keep_dir}" \
       =~ ^(/.+|\.+|(.*/){0,1}\.(git|svn|cvs|hg)(/.*){0,1})$ ]] &&
      continue || :
    # print
    _verbose "#2 Dir '${gk_keep_dir}' is gitkeeping."
    # gitkeep
    [ ${_dry_run:-0} -eq 0 ] && {
      touch "${gk_keep_dir}/${gk_tagname}"
    } || :
    # print
    _echo "+ '${gk_keep_dir}'"
  done < <(
    find "${gk_base_dir}" -type d -a -empty 2>/dev/null |
    sort -u 2>/dev/null; )
done < <(_get_dir_list)

# End
exit 0
