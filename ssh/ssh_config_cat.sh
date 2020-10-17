#!/bin/bash
THIS="${BASH_SOURCE##*/}"
NAME="${THIS%.*}"
CDIR=$([ -n "${BASH_SOURCE%/*}" ] && cd "${BASH_SOURCE%/*}" &>/dev/null; pwd)

# Prohibits overwriting by redirect and use of undefined variables.
set -Cu

# Vars
subcommand=""
ssh_config=""
ssh_cnfdir="${HOME}/.ssh"

# Output (for update)
sahcat_out=""
sshcatdiff=""

# Temp dir.
sc_tmp_dir="${TMPDIR:-/tmp}/.${NAME}.$$"
sc_tmp_cfg=""
sc_tmpdiff=""

# Flags
enable_inc=0
rm_comment=0
ignore_inc=0
_force_upd=0
_dryrun_on=0
_xtrace_on=0

# Ssh
sshcat_ssh="$(type -P ssh)"

# Debug
case "${DEBUG:-NO}" in
0|[Nn][Oo]|[Oo][Ff][Ff])
  ;;
*)
  _dryrun_on=1
  _xtrace_on=1
  ;;
esac || :

# Stdout
_stdout() {
  local row_data=""
  cat | while IFS= read row_data
  do printf "$THIS: %s" "${row_data}"; echo; done
  return 0
}

# Abort
_abort() {
  local exitcode=1 &>/dev/null
  [[ "${1:-}" =~ ^[0-9]+$ ]] && {
    exitcode="${1}"; shift;
  } &>/dev/null
  echo "ERROR: $@" "(${exitcode:-1})" |_stdout 1>&2
  [ ${exitcode:-1} -le 0 ] || exit ${exitcode:-1}
  return 0
}

# Cleanup
_cleanup() {
  [ -n "${sc_tmp_dir}" ] && {
    rm -rf "${sc_tmp_dir}"
  } &>/dev/null || :
  return 0
}

# Subcommand (First option)
case "${1:-}" in
cat|check|update)
  subcommand="$1"; shift
  ;;
up)
  subcommand="update"; shift
  ;;
*)
  subcommand="cat"
  ;;
esac

# Options
while [ $# -gt 0 ]
do
  case "${subcommand}::${1:-}" in
  *::-f*)
    if [ -n "${1##*-f}" ]
    then ssh_config="${1##*-f}"
    else ssh_config="${2:-}"; shift
    fi
    ;;
  cat::--remove-comment*)
    rm_comment=1
    ;;
  cat::--ignore-include*)
    ignore_inc=1
    ;;
  update::-o*)
    if [ -n "${1##*-o}" ]
    then sshcat_out="${1##*-o}"
    else sshcat_out="${2:-}"; shift
    fi
    ;;
  update::--force)
    _force_upd=1
    ;;
  *::-D*|*::-debug*|*::--debug*)
    _xtrace_on=1
    ;;
  *::-n*|*::-dry-run*|*::--dry-run*)
    _dryrun_on=1
    ;;
  *::-h|*::-help*|*::--help*)
    cat <<_USAGE_
Usage: $THIS [cat]  [-f /path/to/ssh_config] (--remove-comment] [--ignore-include]
       $THIS update [-f /path/to/ssh_config] [-o /path/to/ssh_config.out] [--force]
       $THIS check  [-f /path/to/ssh_config]

_USAGE_
    exit 1
    ;;
  *::-*)
    _abort 22 "Illegal option '${1:-}'."
    ;;
  *)
    _abort 22 "Illegal argument '${1:-}'."
    ;;
  esac
  shift
done

# Check
[ -x "${sshcat_ssh}" ] || {
  _abort 127 "ssh '${sshcat_ssh}': Command not found."
}

# Include ?
enable_inc=$(
  : && {
    "${sshcat_ssh}" -oInclude=/dev/null localhost 2>&1 |
    egrep -i 'Bad[[:space:]]+configuration[[:space:]]+option:[[:space:]]+include'
  } &>/dev/null && echo "0" || echo "1"; )

# Include support ?
if [ ${enable_inc} -eq 0 ]
then
  _abort 0 "Your ssh does not support include directive."
fi

# Enable trace, verbose
[ ${_xtrace_on} -eq 0 ] || {
  PS4='>(${THIS:-$THIS}:${LINENO:-0})${FUNCNAME:+:$FUNCNAME()}: '
  export PS4
  set -xv
}

# SSH CONFIG (IN)
[ -n "${ssh_config}" ] || {
  if [ -r "${ssh_cnfdir}/config.tmpl" ]
  then ssh_config="${ssh_cnfdir}/config.tmpl"
  else ssh_config="${ssh_cnfdir}/config"
  fi || :
}
if [ -r "${ssh_config}" ]
then
  # SSH Config Dir
  ssh_cnfdir="${ssh_config%/*}"
else
  _abort 2 "'${ssh_config}': no such file or directory."
fi

# Subcommand check
case "${subcommand}" in
check)
  # Option 'G' support ?
  : && {
    "${sshcat_ssh}" -G -F /dev/null localhost 2>&1 |
    egrep -i '(unknown|illegal)[[:space:]]+option[[:space:]]+--[[:space:]]+G'
  } &>/dev/null && {
    _abort 1 "option 'G' not supported."
  } || :
  ;;
update)
  # Support include directive, No update
  [ ${enable_inc} -ne 0 -a ${_force_upd} -eq 0 ] && {
    : && {
      echo "Your ssh supports include directives."
      echo "There is no need to update."
    } |_stdout
    exit 0
  } || :
  # SSH CONFIG (OUT)
  if [ -n "${sshcat_out}" ]
  then
    sshcat_out="$(
      [ -n "${sshcat_out%/*}" -a "${sshcat_out%/*}" != "${sshcat_out}" ] &&
      cd "${sshcat_out%/*}" 2>/dev/null; pwd)/${sshcat_out##*/}"
  fi
  if [ -z "${sshcat_out}" ]
  then
    sshcat_out="${ssh_cnfdir}/config"
  fi
  [ -n "${sshcat_out%/*}" -a -d "${sshcat_out%/*}" ] || {
    _abort 2 "'${sshcat_out%/*}' no such file or directory."
  }
  ;;
*)
  ;;
esac

# Temp dir and file.
[ -d "${sc_tmp_dir}" ] || {

  mkdir -p "${sc_tmp_dir}" &>/dev/null &&
  chmod 0700 "${sc_tmp_dir}" &>/dev/null &&
  if [ "${subcommand}" != "cat" -a ${enable_inc} -eq 0 ] ||
     [ ${_force_upd} -ne 0 ]
  then
    sc_tmp_cfg="${sc_tmp_dir}/${ssh_config##*/}.tmp"
    touch "${sc_tmp_cfg}" &>/dev/null || :
  else : "noop"
  fi

} 1>/dev/null

# Set trap
trap "_cleanup" SIGTERM SIGHUP SIGINT SIGQUIT
trap "_cleanup" EXIT

# Print
if [ "${subcommand}" = "cat" -o $enable_inc -eq 0 -o $_force_upd -ne 0 ]
then

  cat "${ssh_config}" |
  while IFS= read row_data 2>/dev/null
  do

    if [ ${rm_comment} -ne 0 ]
    then
      if [ -n "${row_data}" ]
      then row_data=$(echo ${row_data%%#*})
      fi
      if [ -z "${row_data}" ]
      then continue
      fi
    fi || :

    : && {
      printf "%b" "${row_data}" |
      egrep -i '^[[:space:]]*include[[:space:]]+[^[:space:]].*$' &>/dev/null || {
        printf "%b" "${row_data}"; echo
        continue
      }
    } 2>/dev/null

    inc_file="${row_data%%#*}"
    inc_file=$(
      echo "${inc_file#*nclude}" |tr '\t' ' ' |
      sed -e 's;  *; ;g' -e 's;^ *;;g' -e 's; *$;;' 2>/dev/null)

    if [ $ignore_inc -eq 0 ]
    then

      echo "# {{{ Include ${inc_file}"

      ( if [ -n "${inc_file}" ]
        then
          if [ -n "${ssh_cnfdir}" ]
          then cd "${ssh_cnfdir}" 2>/dev/null
          else :
          fi
          cat ${inc_file}
        else
          echo "# ERROR: '${inc_file}': no such file or dir."
        fi; )

      echo "# }}} Include ${inc_file}"

    else
      echo "# {{{ Include ${inc_file} }}}"
    fi

  done |
  if [ -n "${sc_tmp_cfg}" ]
  then cat 1>|"${sc_tmp_cfg}"
  else cat
  fi

else : "noop"
fi &&
: "Check or Update" &&
case "${subcommand}" in
check)
  : "Check" && {

    exec 1>| >(_stdout)

    sshcatopts="-Gv"
    sshcatopts="${sshcatopts} -F $(
      if [ -s "${sc_tmp_cfg}" ]
      then echo "${sc_tmp_cfg}"
      else echo "${ssh_config}"
      fi 2>/dev/null; )"

    # Check
    "${sshcat_ssh}" ${sshcatopts} localhost &&
    { echo "Syntax OK."; } ||
    { echo "Syntax NG."; false; }

  } ;;

update)
  : "Update" && {

    exec 1>| >(_stdout)

    if [ -s "${sc_tmp_cfg}" ]
    then

      sshcatdiff="${sshcat_out}-$(date +'%Y%m%dT%H%M%S').patch"
      sc_tmpdiff="${sc_tmp_dir}/${ssh_config##*/}.diff"

      sc_diffret=0

      if [ ${_force_upd} -eq 0 ]
      then
        diff -u "${sc_tmp_cfg}" "${sshcat_out}" 1>|"${sc_tmpdiff}" 2>/dev/null
        sc_diffret=$?
      else
        sc_diffret=1
      fi

      if [ ${sc_diffret} -ne 0 ]
      then

        cat "${sc_tmp_cfg}" 1>|"${sshcat_out}" && {
          [ -s "${sc_tmpdiff}" ] &&
          cat "${sc_tmpdiff}" 1>|"${sshcatdiff}" || :
        } && echo "Update succeeded."

      else
        echo "No difference, No update."; false
      fi 2>/dev/null

    fi

  } ;;

*)
  : "noop" ;;
esac

# End
exit $?
