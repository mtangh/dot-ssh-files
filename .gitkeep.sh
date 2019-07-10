#!/bin/bash
THIS="${0##*/}"
CDIR=$([ -n "${0%/*}" ] && cd "${0%/*}" 2>/dev/null; pwd)
# Name
THIS="${THIS:-gitkeep.sh}"
BASE="${THIS%.*}"

# Base directories.
basedirs=""

# Tag file
_tagname=".${BASE}"

# Flags
_rebuild=0
_cleanup=0
_verbose=0
_quietly=0
_dry_run=0
_debug_f=0

# Usage
usage() {
  local exitstat="${1:-1}"
  cat <<_USAGE_
Usage: $THIS [OPTION] [dir...]

OPTION:
-R,--rebuild
  Delete all gitkeep and rebuild..
-d,--dry-run
  Enable dry-run mode.
-v,--verbose
  Verbose print.

_USAGE_
  exit $exitstat
}

# dir list
_get_dir_list() {
  local _dirpath=""
  printf "%b" "${basedirs}" |sort -u |egrep -v '^$' |
  while read _dirpath
  do
    [[ $_dirpath =~ /$ ]] && {
      _dirpath="${_dirpath%/*}"
    }
    echo "$_dirpath"
  done
  return 0
}

# Echo
_echo() {
  [ ${_quietly} -eq 0 ] && {
    echo "${BASE}: $@"
  } || :
  return 0
}

# Verbose
_verbose() {
  [ ${_verbose} -ne 0 ] && {
    _echo "$@";
  } || :
  return 0
}

# Options
while [ $# -gt 0 ]
do
  case "$1" in
  -t*)
    if [ -n "${1#*-t}" ]
    then _tagname="${1#*-t}"
    else _tagname="$2"; shift
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
    if [ -d "${1}" ]
    then
      # Base dir
      basedirs="${basedirs}${1}\n"
    else
      echo "${BASE}: no such directory '${1}'." 1>&2
      exit 1
    fi
    ;;
  esac
  shift
done

# No unbound vars
set -Cu

# Enable trace, verbose
[ $_debug_f -eq 0 ] || {
  PS4='>(${BASH_SOURCE:-$THIS}:${LINENO:-0})${FUNCNAME:+:$FUNCNAME()}: ';
  export PS4
  set -xv
  _dry_run=1
}

# Set default '.' (if empty)
basedirs="${basedirs:-.\n}"

# Tag name
[ -n "${_tagname}" ] && {
  _tagname=".${BASE}"
} || :
echo "${_tagname}" |
egrep '^[.].+' 1>/dev/null 2>&1 || {
  _tagname=".${_tagname}"
}

# Work
base_dir=""
keep_dir=""

# Cleanup
[ ${_cleanup} -ne 0 ] && {

  findcmd=$(
    [ $_dry_run -eq 0 ] && echo "rm -f"
    [ $_dry_run -eq 0 ] || echo "echo"; )

  # Remove gitkeep
  _get_dir_list |
  while read base_dir
  do
    # Print
    _echo "Cleanup: '$base_dir'."
    # Find 'gitkeep' file under the base_dir and remove it.
    find "${base_dir}" \
      -name "${_tagname}" -a -type f \
      -print -exec $findcmd {} \; |
    while read printent
    do
      _verbose "Cleanup: '${printent}'."
    done
  done 2>/dev/null
  # Rebuild ?
  [ $_rebuild -eq 0 ] && {
    exit 0
  }

} || : # [ ${_cleanup} -ne 0 ]

# Process dirs
_get_dir_list |
while read base_dir
do

  _echo "Gitkeep directory '$base_dir'."

  find "$base_dir" -type d |sort -u |
  while read keep_dir
  do

    _verbose "#1 Check dir '${keep_dir}'"

    echo "${keep_dir}" |
    egrep '^(/.+|\.+|(.*/){0,1}\.(git|svn|cvs|hg)(/.*){0,1})$' 1>&2 &&
      continue

    _verbose "#2 Dir '${keep_dir}' have a child ?"

    echo $(ls -1A "${keep_dir}" |wc -l) |
    egrep -v '^0$' 1>&2 &&
      continue

    _verbose "#3 Dir '${keep_dir}' is have not child."

    [ -e "${keep_dir}/${_tagname}" ] &&
      continue

    _verbose "#4 Dir '${keep_dir}' is gitkeeping."

    [ $_dry_run -eq 0 ] &&
      touch "${keep_dir}/${_tagname}"

    _echo "+ '${keep_dir}'"

  done

done 2>/dev/null

# End
exit 0
