#!/bin/bash
THIS="${BASH_SOURCE##*/}"
CDIR=$([ -n "${BASH_SOURCE%/*}" ] && cd "${BASH_SOURCE%/*}" &>/dev/null; pwd)

# Run teats
echo "[${tests_name}] install.sh" && {

  bash -n install.sh &&
  bash -x install.sh && {
    [ -r "$HOME/.ssh/config" ] &&
    [ -r "$HOME/.ssh/default.conf" ] &&
    [ -d "$HOME/.ssh/config.d/" ] &&
    [ -f "$HOME/.ssh/config.d/00_localhost.conf" ] &&
    [ -f "$HOME/.ssh/config.d/02_localnetwork-classA.conf" ] &&
    [ -f "$HOME/.ssh/config.d/02_localnetwork-classB.conf" ] &&
    [ -f "$HOME/.ssh/config.d/02_localnetwork-classC.conf" ] &&
    [ -d "$HOME/.ssh/keys/" ] &&
    [ -x "$HOME/.ssh/ssh_config_cat.sh" ] &&
    [ -x "$HOME/.ssh/ssh_config_check.sh" ] &&
    ( cd "${HOME}/.config/dot-ssh-files" &&
      git config --get core.filemode |
      grep -Ei '^false$'; )
  }

} &&
echo "[${tests_name}] DONE."

# End
exit $?
