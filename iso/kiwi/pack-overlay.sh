#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Assemble the OBS package sources for the live ISO under iso/build/obs/: the KIWI
# description, config.sh and root/ packed as patina21-root.tar.xz (OBS packages hold
# files, not directories). Upload the result with osc; nothing here is committed.
set -euo pipefail

here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
out="${1:-$here/../build/obs}"

mkdir -p "$out"
cp "$here/patina21.kiwi" "$here/config.sh" "$out/"
# Reproducible: fixed owner, sorted entries, timestamps from the last commit.
epoch="$(git -C "$here" log -1 --format=%ct 2>/dev/null || date +%s)"
tar --create --xz --file "$out/patina21-root.tar.xz" \
  --directory "$here/root" --owner=0 --group=0 --numeric-owner --sort=name \
  --mtime="@$epoch" .
printf 'OBS sources in %s:\n' "$out"
ls -l "$out"
