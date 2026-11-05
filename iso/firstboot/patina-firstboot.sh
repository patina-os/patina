#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# First boot after the patina image: do exactly what Path A does for the user Calamares
# created, then get out of the way. Idempotent and safe to re-run by hand.
set -euo pipefail

state_dir=/var/lib/patina
done_marker="$state_dir/firstboot-done"
# A start that fails leaves the first boot armed for the next one, up to this many.
tries_file="$state_dir/firstboot-tries"
max_tries=3
log=/var/log/patina-firstboot.log
repo_url="${PATINA_REPO_URL:-https://github.com/patina-os/patina.git}"
repo_ref="${PATINA_REPO_REF:-main}"

# Answers for `patina install`: the installer writes PATINA_AI_AGENT, PATINA_AI,
# PATINA_BUNDLES and PATINA_THEME (its agent, AI, apps, more-apps and theme pages,
# modules/shellprocess-firstboot.conf), so the install asks nothing but the user's
# password for sudo; a cloud agent's provider and key are the welcome's at the first
# login (patina ai login). PATINA_AI_PROVIDER and PATINA_UNATTENDED=1 may be added by
# hand for unattended runs. An image older than those pages writes PATINA_AI alone,
# and the install asks the rest.
# shellcheck disable=SC1091  # written at install time, absent on a hand-made system
[[ -r /etc/patina/firstboot.env ]] && source /etc/patina/firstboot.env

say() {
  # The console (tty1 here) and, with console=ttyS0, the serial line the test watches;
  # the journal too (journalctl -u patina-firstboot), for a test report.
  printf 'patina firstboot: %s\n' "$*" | tee /dev/console >/dev/null 2>&1 || true
  logger -t patina-firstboot -- "$*" 2>/dev/null || true
}

# A failure is said on tty1, and the login screen would cover it at once: hold it there
# until Enter, or for five minutes, so it can be read.
hold() {
  say "$*"
  printf '\nPress Enter to go on to the login screen.\n'
  read -r -t 300 _ || true
}

finish() {
  mkdir -p "$state_dir"
  date -u +%FT%TZ > "$done_marker"
  rm -f "$tries_file"
}

# A failure ends this start and leaves the first boot armed, so the next start tries
# again; after the last of max_tries it gets out of the way, and Path A by hand is left.
# retry_later <what failed> <what to do by hand>
retry_later() {
  local tries
  mkdir -p "$state_dir"
  tries=$(($(cat "$tries_file" 2>/dev/null || echo 0) + 1))
  echo "$tries" > "$tries_file"
  if [[ $tries -lt $max_tries ]]; then
    hold "$1; the next start tries again (try $tries of $max_tries), or log in and $2"
  else
    hold "$1, at the last of $max_tries starts; log in and $2"
    finish
  fi
  exit 0
}

clear 2>/dev/null || true
# The user Calamares created: the first regular account with a home directory.
user="$(getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 && $6 ~ /^\/home\// { print $1; exit }')"
if [[ -z "$user" ]]; then
  hold "no regular user found; run 'git clone $repo_url' and 'patina install' by hand"
  finish
  exit 0
fi
home="$(getent passwd "$user" | cut -d: -f6)"
clone="$home/.local/share/patina"

# The network can come up a little after network-online.target (Wi-Fi, a slow DHCP
# server, DNS), so the clone gets three tries before this start gives up. It goes to a
# directory of its own and takes its place only when complete: a machine turned off in
# the middle of it left a checkout without its files, which patina install then failed
# on, and the first boot counted as done.
if [[ ! -d "$clone/.git" ]]; then
  runuser -u "$user" -- mkdir -p "$home/.local/share" "$home/.local/bin"
  for try in 1 2 3; do
    rm -rf "$clone.new"
    say "cloning $repo_url ($repo_ref) for $user"
    # Without the files of old commits (a partial clone, a quarter of the full one's
    # size, which still updates and names its version), and a clone that stalls below
    # 1 KB/s for a minute ends and is tried again: a virtual machine's network can stop.
    if runuser -u "$user" -- git -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 \
      clone --filter=blob:none --branch "$repo_ref" "$repo_url" "$clone.new"; then
      rm -rf "$clone"
      runuser -u "$user" -- mv "$clone.new" "$clone"
      break
    fi
    rm -rf "$clone.new"
    if [[ $try -eq 3 ]]; then
      retry_later "the clone failed (no network?)" \
        "run Path A by hand: git clone $repo_url ~/.local/share/patina, then ~/.local/share/patina/bin/patina install"
    fi
    sleep $((try * 20))
  done
fi
runuser -u "$user" -- ln -sfn "$clone/bin/patina" "$home/.local/bin/patina"

# The mark on the console, unless the install asks its questions, which print it
# themselves: the installer's answers (PATINA_BUNDLES) or an unattended run ask none.
if [[ -n "${PATINA_UNATTENDED:-}${PATINA_BUNDLES:-}" && -r "$clone/branding/logo.txt" ]]; then
  cat "$clone/branding/logo.txt"
  echo
fi
# sudo asks for the password the installer set, as on Path A, on this terminal.
say "running 'patina install' as $user; sudo asks for $user's password, the one" \
  "given to the installer (or to Try patina's setup); the output is kept in $log"
export PATINA_THEME="${PATINA_THEME:-}" PATINA_UNATTENDED="${PATINA_UNATTENDED:-}" \
  PATINA_AI_AGENT="${PATINA_AI_AGENT:-}" PATINA_AI="${PATINA_AI:-}" \
  PATINA_AI_PROVIDER="${PATINA_AI_PROVIDER:-}"
args=()
[[ -z "${PATINA_BUNDLES:-}" ]] || args+=(--bundles "$PATINA_BUNDLES")
# script(1) keeps what the install prints, as docs/vm-run.md does for Path A, and gives
# it a terminal of its own, so its questions and sudo's password prompt still work. A
# run by hand adds to the log.
command="$(printf '%q ' runuser -u "$user" \
  --whitelist-environment=PATINA_THEME,PATINA_UNATTENDED,PATINA_AI_AGENT,PATINA_AI,PATINA_AI_PROVIDER \
  -- "$clone/bin/patina" install "${args[@]}")"
[[ -e "$log" ]] || install -m 0600 /dev/null "$log"
if SHELL=/bin/bash script --quiet --append --flush --return --command "$command" "$log"; then
  say "done"
else
  retry_later "patina install exited with an error (its output: sudo less -R $log)" "run 'patina install' again"
fi
finish
