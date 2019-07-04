#!/bin/bash
THIS="${0##*/}"
CDIR=$([ -n "${0%/*}" ] && cd "${0%/*}" 2>/dev/null; pwd)
# Name
THIS="${THIS:-ssh_config_cat.sh}"
BASE="${THIS%.*}"

# Vars
ssh_config=""

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

# Print
cat "${ssh_config}" |
while read row_data
do

  [ $rm_comment -ne 0 -a -n "${row_data}" ] && {
    row_data=$(echo "${row_data%#*}")
    [ -n "${row_data}" ] &&
      continue
  } || :

  printf "%s" "${row_data}" |
  egrep -i '^[ \t]*include[ \t]+[^ \t].*$' 1>/dev/null || {
    echo "${row_data}"
    continue
  }

  row_data="${row_data%#*}"

  inc_file=$(
    echo "${row_data#*nclude}" |tr '\t' ' ' |
    sed -e 's;  *; ;g' -e 's;^ *;;g' -e 's; *$;;')

  if [ $ignore_inc -eq 0 ]
  then
    echo "# <<< Include ${inc_file}"
    ( cd "${ssh_config%/*}" &&
      cat ${inc_file} /dev/null; )
    echo "# >>> Include ${inc_file}"
  else
    echo "# <<< Include ${inc_file} >>>"
  fi

done 2>/dev/null

# End
exit 0
