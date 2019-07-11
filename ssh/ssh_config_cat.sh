#!/bin/bash
THIS="${0##*/}"
CDIR=$([ -n "${0%/*}" ] && cd "${0%/*}" 2>/dev/null; pwd)
# Name
THIS="${THIS:-ssh_config_cat.sh}"
BASE="${THIS%.*}"

# Vars
ssh_config=""
ssh_cnfdir=""

# Flags
rm_comment=0
ignore_inc=0

# Options
while [ $# -gt 0 ]
do
  case "$1" in
  -f*)
    if [ -n "${1##*-f}" ]
    then ssh_config="${1##*-f}"
    else ssh_config="${2}"; shift
    fi
    ;;
  --remove-comment*)
    rm_comment=1
    ;;
  --ignore-include*)
    ignore_inc=1
    ;;
  -h|-help*|--help*)
    cat <<_USAGE_
Usage: $THIS [-f /path/to/ssh_config] [--remove-comment] [--ignore-include]

_USAGE_
    exit 1
    ;;
  *)
    ;;
  esac
  shift
done

# No unbound vars
set -Cu

# SSH config
[ -n "${ssh_config}" ] || {
  ssh_config="${HOME}/.ssh/config"
}
[ -r "${ssh_config}" ] || {
  cat <<_MSG_
$THIS: ERRROR '${ssh_config}' no such file or directory.
_MSG_
  exit 1
}

# SSH Config Dir
ssh_cnfdir="${ssh_config%/*}"

# Print
cat "${ssh_config}" |
while read row_data
do

  if [ $rm_comment -ne 0 ]
  then
    if [ -n "${row_data}" ]
    then
      row_data=$(echo ${row_data%%#*})
    fi
    if [ -z "${row_data}" ]
    then
      continue
    fi
  fi || :

  printf "%s" "${row_data}" |
  egrep -i '^[ \t]*include[ \t]+[^ \t].*$' 1>/dev/null || {
    printf "%s" "${row_data}"; echo
    continue
  }

  inc_file="${row_data%%#*}"
  inc_file=$(
    echo "${inc_file#*nclude}" |tr '\t' ' ' |
    sed -e 's;  *; ;g' -e 's;^ *;;g' -e 's; *$;;')

  if [ $ignore_inc -eq 0 ]
  then

    echo "# <<< Include ${inc_file}"

    ( if [ -n "${ssh_cnfdir}" ]
      then cd "${ssh_cnfdir}"
      else :
      fi
      if [ -z "${inc_file}" ]
      then cat ${inc_file}
      else echo "# ERROR: '${inc_file}': no such file or dir."
      fi; )

    echo "# >>> Include ${inc_file}"

  else
    echo "# <<< Include ${inc_file} >>>"
  fi

done 2>/dev/null

# End
exit 0
