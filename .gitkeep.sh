#!/bin/bash
THIS="${BASH_SOURCE##*/}"
NAME="${THIS%.*}"
CDIR=$([ -n "${BASH_SOURCE%/*}" ] && cd "${BASH_SOURCE%/*}" 2>/dev/null; pwd)

# Prohibits overwriting by redirect and use of undefined variables.
set -Cu

# Base directories.
gkbasedirs=""

# Tag file
gk_tagname=".${NAME}"

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
  cat <<_USAGE_ 2/dev/null
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
  printf "%b" "${gkbasedirs}" 2>/dev/null |
  sort -u 2>/dev/null |
  while read _dirpath
  do
    [[ $_dirpath =~ ^$ ]] &&
    [[ $_dirpath =~ /$ ]] && {
      _dirpath="${_dirpath%/*}"
    } 2>/dev/null || :
    echo "$_dirpath"
  done || :
  return 0
}

# Echo
_echo() {
  [ ${_quietly} -eq 0 ] && {
    echo "${NAME}: $@"
  } 2>/dev/null || :
  return 0
}

# Verbose
_verbose() {
  [ ${_verbose} -ne 0 ] && {
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
    else gk_tagname="$2"; shift
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
      gkbasedirs="${gkbasedirs}${1}\n"
    else
      echo "${THIS}: '${1:-}': no such file or directory." 1>&2
      exit 2
    fi
    ;;
  esac
  shift
done

# Enable trace, verbose
[ $_debug_f -eq 0 ] || {
  PS4='>(${BASH_SOURCE:-$THIS}:${LINENO:-0})${FUNCNAME:+:$FUNCNAME()}: ';
  export PS4
  set -xv
  _dry_run=1
}

# Set default '.' (if empty)
gkbasedirs="${gkbasedirs:-.\n}"

# Tag name
[ -z "${gk_tagname}" ] || {
  gk_tagname=".${NAME}"
}
[[ "${gk_tagname}" =~ ^[.].+ ]] &>/dev/null || {
  gk_tagname=".${gk_tagname}"
}

# Work
gk_base_dir=""
gk_keep_dir=""

# Cleanup
[ ${_cleanup} -ne 0 ] && {

  _findcmd=$(
    [ $_dry_run -eq 0 ] && echo "rm -f"
    [ $_dry_run -eq 0 ] || echo "echo"; )

  # Remove gitkeep
  _get_dir_list |
  while read gk_base_dir
  do
    # Print
    _echo "Cleanup: '$gk_base_dir'."
    # Find 'gitkeep' file under the gk_base_dir and remove it.
    find "${gk_base_dir}" \
      -name "${gk_tagname}" -a -type f \
      -print -exec ${_findcmd} {} \; 2>/dev/null |
    while read _printent
    do
      _verbose "Cleanup: '${_printent}'."
    done 2>/dev/null
  done
  # Rebuild ?
  [ $_rebuild -eq 0 ] && {
    exit 0
  }

} || : # [ ${_cleanup} -ne 0 ]

# Process dirs
_get_dir_list |
while read gk_base_dir
do

  _echo "Gitkeep directory '${gk_base_dir}'."

  find "$gk_base_dir" -type d 2>/dev/null |
  sort -u 2>/dev/null |
  while read gk_keep_dir
  do

    _verbose "#1 Check dir '${gk_keep_dir}'"

    [[ "${gk_keep_dir}" \
       =~ ^(/.+|\.+|(.*/){0,1}\.(git|svn|cvs|hg)(/.*){0,1})$ ]] &&
      continue || :

    _verbose "#2 Dir '${gk_keep_dir}' have a child ?"

    [[ $(ls -1A ${gk_keep_dir} |wc -l 2>/dev/null) =~ ^[\ \\t]*0$ ]] ||
      continue

    _verbose "#3 Dir '${gk_keep_dir}' is have not child."

    [ -e "${gk_keep_dir}/${gk_tagname}" ] &&
      continue

    _verbose "#4 Dir '${gk_keep_dir}' is gitkeeping."

    [ $_dry_run -eq 0 ] && {
      touch "${gk_keep_dir}/${gk_tagname}"
    } || :

    _echo "+ '${gk_keep_dir}'"

  done

done

# End
exit 0
