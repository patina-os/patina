#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Build the patina live image with live-build: assemble the build directory from the
# committed configuration, what assets.sh renders from branding/ and the theme, and
# iso/firstboot/, then run lb. Needs root (debootstrap), live-build, yq, rsvg-convert and
# the fonts; see iso/README.md.
set -euo pipefail
# The files this script, assets.sh and live-build create keep these modes in the image and,
# through unpackfs, in the installed system: never world-writable, whatever the caller's umask.
umask 022

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
# An architecture's own apt pins for the build (live-build takes them out of the image
# again) and its own live-build options, one to a line.
if [[ -e "$here/arch/$arch.pref.chroot" ]]; then
  install -D -m 0644 "$here/arch/$arch.pref.chroot" "$out/config/archives/patina-$arch.pref.chroot"
fi
options=()
if [[ -e "$here/arch/$arch.lb-config" ]]; then
  while read -ra words; do
    [[ ${#words[@]} -eq 0 || "${words[0]}" == \#* ]] || options+=("${words[@]}")
  done < "$here/arch/$arch.lb-config"
fi
chroot="$out/config/includes.chroot"

# First boot: the same unit and script Path A is run by (iso/firstboot/).
install -D -m 0755 "$repo/iso/firstboot/patina-firstboot.sh" \
  "$chroot/usr/local/lib/patina/firstboot.sh"
install -D -m 0644 "$repo/iso/firstboot/patina-firstboot.service" \
  "$chroot/etc/systemd/system/patina-firstboot.service"

# Everything the image shows, rendered from branding/ and the default theme: the console
# mark, the installer's marks, artwork and stylesheet, the boot menu's theme.
"$here/assets.sh" "$out"

# The devices of this architecture whose boot loader must hand the kernel a device
# tree (a model with `menu`, devices/README.md): the boot menu's entries for them, as
# two files live-build fills with the live kernel's names like its own menu, and the
# hook that names the entries puts into the menu with the trees. devices.cfg holds the
# entries of the models the firmware's product name matches, before "Install patina";
# devices-all.cfg all of them in a submenu, for a laptop whose firmware says another
# name. An entry's command line carries the device's kernel parameters, and the
# device and its tree for the installer (device-boot.sh), which copies the device's
# system files, put beside its configuration here, to the disk.
case "$arch" in
  amd64) machine=x86_64 ;;
  arm64) machine=aarch64 ;;
esac
grub="$out/config/bootloaders/grub-pc"
for f in "$repo"/devices/[a-z]*/device.yaml; do
  [[ "$(yq eval '.arch' "$f")" == "$machine" ]] || continue
  yq eval -e '[.models[]? | select(.menu)] | length > 0' "$f" > /dev/null 2>&1 || continue
  slug="$(basename "$(dirname "$f")")"
  params="$(yq eval '.kernel_params // [] | join(" ")' "$f")"
  if [[ -d "$repo/devices/$slug/system" ]]; then
    mkdir -p "$chroot/etc/calamares/devices"
    cp -r "$repo/devices/$slug/system" "$chroot/etc/calamares/devices/$slug"
  fi
  printf 'submenu "%s..." {\n\tsource /boot/grub/theme.cfg\n' "$(yq eval '.menu // .name' "$f")" \
    >> "$grub/devices-all.cfg"
  while IFS=$'\t' read -r label tree smbios; do
    entry="$(printf 'menuentry "Install on %s" {\n\tdevicetree /boot/dtb/%s\n\tlinux\t%s %s %s patina.device=%s patina.devicetree=%s\n\tinitrd\t%s\n}' \
      "$label" "$tree" @KERNEL_LIVE@ @APPEND_LIVE@ "$params" "$slug" "$tree" @INITRD_LIVE@)"
    printf '%s\n' "$entry" >> "$grub/devices-all.cfg"
    # shellcheck disable=SC2016  # $patina_product is GRUB's variable, read at boot
    [[ -z "$smbios" ]] || printf 'if regexp %s "$patina_product"; then\n%s\nfi\n' \
      "'$smbios'" "$entry" >> "$grub/devices.cfg"
  done < <(yq eval '.models[] | select(.menu) | .menu + "\t" + .dtb + "\t" + (.smbios // "")' "$f")
  echo '}' >> "$grub/devices-all.cfg"
done
# The product name the firmware reports (SMBIOS, type 1), once, before the entries ask.
[[ ! -e "$grub/devices.cfg" ]] || sed -i '1i smbios --type 1 --get-string 5 --set patina_product' "$grub/devices.cfg"

cd "$out"
PATINA_ARCH="$arch" lb config "${options[@]}"
lb build 2>&1 | tee "$out/build.log"
ls -l "$out"/*.iso
