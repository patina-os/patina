#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Build the patina21 live image with live-build: assemble the build directory from the
# committed configuration plus what is generated from branding/ and iso/firstboot/, then
# run lb. Needs root (debootstrap), live-build and yq; see iso/README.md.
set -euo pipefail

here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
arch="${1:-amd64}"
out="${2:-$repo/iso/build/live}"

case "$arch" in
  amd64 | arm64) ;;
  *) echo "build.sh: architecture must be amd64 or arm64, not '$arch'" >&2; exit 64 ;;
esac
for tool in lb yq git; do
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

# The logo from its only copy: the console mark, and an SVG of the same text for the
# installer's sidebar and welcome page. agetty reads backslashes in /etc/issue as
# escape sequences, so the console copy doubles them.
install -d -m 0755 "$chroot/etc/issue.d"
sed 's/\\/\\\\/g' "$repo/branding/logo.txt" > "$chroot/etc/issue.d/10-patina21.issue"
branding="$chroot/etc/calamares/branding/patina21"
{
  echo '<svg xmlns="http://www.w3.org/2000/svg" width="520" height="120" viewBox="0 0 520 120">'
  echo '  <rect width="100%" height="100%" fill="#1e1e1e"/>'
  y=20
  # The wordmark is plain text, not YAML, so sed may escape it for XML.
  while IFS= read -r line; do
    printf '  <text x="12" y="%d" font-family="monospace" font-size="14" fill="#d0d0d0" xml:space="preserve">%s</text>\n' \
      "$y" "$line"
    y=$((y + 16))
  done < <(sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' "$repo/branding/logo.txt")
  echo '</svg>'
} > "$branding/logo.svg"

version="$(git -C "$repo" describe --tags --always --dirty 2> /dev/null || echo 0.0.0-unknown)"
yq -i ".strings.version = \"$version\" | .strings.shortVersion = \"$version\"" \
  "$branding/branding.desc"

cd "$out"
PATINA_ARCH="$arch" lb config
lb build 2>&1 | tee "$out/build.log"
ls -l "$out"/*.iso
