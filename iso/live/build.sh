#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Build the patina21 live image with live-build: assemble the build directory from the
# committed configuration, what assets.sh renders from branding/ and the theme, and
# iso/firstboot/, then run lb. Needs root (debootstrap), live-build, yq, rsvg-convert and
# the fonts; see iso/README.md.
set -euo pipefail

here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
arch="${1:-amd64}"
out="${2:-$repo/iso/build/live}"

case "$arch" in
  amd64 | arm64) ;;
  *) echo "build.sh: architecture must be amd64 or arm64, not '$arch'" >&2; exit 64 ;;
esac
for tool in lb yq git rsvg-convert; do
  command -v "$tool" > /dev/null || { echo "build.sh: $tool missing" >&2; exit 69; }
done
[[ "$(id -u)" -eq 0 ]] || { echo "build.sh: run as root; live-build needs it" >&2; exit 77; }

rm -rf "$out"
mkdir -p "$out"
cp -r "$here/config" "$here/auto" "$out/"
cp "$here/arch/$arch.list.chroot" "$out/config/package-lists/"
chroot="$out/config/includes.chroot"

# First boot: the same unit and script Path A is run by (iso/firstboot/).
install -D -m 0755 "$repo/iso/firstboot/patina21-firstboot.sh" \
  "$chroot/usr/local/lib/patina21/firstboot.sh"
install -D -m 0644 "$repo/iso/firstboot/patina21-firstboot.service" \
  "$chroot/etc/systemd/system/patina21-firstboot.service"

# Everything the image shows, rendered from branding/ and the default theme: the console
# mark, the installer's marks, artwork and stylesheet, the boot menu's theme.
"$here/assets.sh" "$out"

cd "$out"
PATINA_ARCH="$arch" lb config
lb build 2>&1 | tee "$out/build.log"
ls -l "$out"/*.iso
