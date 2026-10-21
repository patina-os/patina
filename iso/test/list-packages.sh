#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Print every package the bundles and the live image name, one per line, for apt's dry
# run in the smoke workflow: a wrong name fails CI before it fails a build.
set -euo pipefail

arch="${1:-amd64}"
here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
live="$repo/iso/live"

{
  for bundle in "$repo"/manifest/bundles/[a-z]*.yaml; do
    yq eval '.packages[]' "$bundle"
  done
  yq eval '.operations[].install[]?' \
    "$live/config/includes.chroot/etc/calamares/modules/packages.conf"
  # live-build lists are plain text, one package per line, with # comments.
  grep -h -v -E '^\s*(#|$)' "$live"/config/package-lists/*.list.chroot \
    "$live/arch/$arch.list.chroot"
} | sort -u
