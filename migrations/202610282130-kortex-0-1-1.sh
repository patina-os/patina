#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# kortex 0.1.1, its minimal icon: where kortex is installed at an older ref, install the
# ref manifest/upstream.yaml pins now, through kortex's own install script, as
# `patina install` does. Idempotent: the recorded ref decides.
set -euo pipefail

# shellcheck source=bin/lib.sh
source "$PATINA_PATH/bin/lib.sh"
upstream="$PATINA_PATH/manifest/upstream.yaml"
record="$PATINA_STATE/upstream/kortex"
[[ -f "$record" ]] || exit 0
ref="$(yq eval '.kortex.ref' "$upstream")"
[[ "$(cat "$record")" != "$ref" ]] || exit 0
clone="${XDG_CACHE_HOME:-$HOME/.cache}/patina/upstream/kortex"
rm -rf "$clone"
git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$ref" \
  "$(yq eval '.kortex.url' "$upstream")" "$clone"
(cd "$clone" && "./$(yq eval '.kortex.install' "$upstream")")
rm -rf "$clone"
echo "$ref" > "$record"
say "kortex: $ref installed"
