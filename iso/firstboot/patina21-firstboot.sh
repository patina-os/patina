#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# First boot after the patina21 ISO: do exactly what Path A does for the user Agama
# created, then get out of the way. Idempotent and safe to re-run by hand.
set -euo pipefail

state_dir=/var/lib/patina21
done_marker="$state_dir/firstboot-done"
repo_url="${PATINA_REPO_URL:-https://github.com/patina21/patina21.git}"
repo_ref="${PATINA_REPO_REF:-main}"

# Optional answers for unattended runs (the CI install test writes this file):
# PATINA_THEME, PATINA_UNATTENDED=1. `patina install` honours them (roadmap, Phase 1).
# shellcheck disable=SC1091  # optional, created by the Agama profile of the install test
[[ -r /etc/patina21/firstboot.env ]] && source /etc/patina21/firstboot.env

say() {
  # The console (tty1 here) and, with console=ttyS0, the serial line the test watches.
  printf 'patina21 firstboot: %s\n' "$*" | tee /dev/console >/dev/null 2>&1 || true
}

finish() {
  mkdir -p "$state_dir"
  date -u +%FT%TZ > "$done_marker"
}

clear 2>/dev/null || true
# The user Agama created: the first regular account with a home directory.
user="$(getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 && $6 ~ /^\/home\// { print $1; exit }')"
if [[ -z "$user" ]]; then
  say "no regular user found; run 'git clone $repo_url' and 'patina install' by hand"
  finish
  exit 0
fi
home="$(getent passwd "$user" | cut -d: -f6)"
clone="$home/.local/share/patina21"

if [[ ! -d "$clone/.git" ]]; then
  say "cloning $repo_url ($repo_ref) for $user"
  runuser -u "$user" -- mkdir -p "$home/.local/share" "$home/.local/bin"
  if ! runuser -u "$user" -- git clone --branch "$repo_ref" "$repo_url" "$clone"; then
    say "clone failed (no network?); log in and run Path A by hand: git clone $repo_url"
    finish
    exit 0
  fi
fi
runuser -u "$user" -- ln -sfn "$clone/bin/patina" "$home/.local/bin/patina"

if [[ -r "$clone/branding/logo.txt" ]]; then
  cat "$clone/branding/logo.txt"
  echo
fi
say "running 'patina install' as $user"
export PATINA_THEME="${PATINA_THEME:-}" PATINA_UNATTENDED="${PATINA_UNATTENDED:-}"
if runuser -u "$user" --whitelist-environment=PATINA_THEME,PATINA_UNATTENDED \
    -- "$clone/bin/patina" install; then
  say "done"
else
  say "patina install exited with an error; run 'patina install' again after logging in"
fi
finish
