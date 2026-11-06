#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Put shim at the EFI partition's removable path, unless another system's loader is there.
set -euo pipefail

# Runs on the live system after the bootloader step (shellprocess-efi-removable.conf),
# with the target's root as $1, which the mount step gave /proc, /sys and /dev. The
# removable path (EFI/BOOT/BOOT<arch>.EFI), which firmware boots when its boot entries
# are lost, gets shim and the signed GRUB beside it, so such a machine still boots, with
# Secure Boot or without. It is Debian's own option, grub2/force_efi_extra_removable,
# the one its installer offers: set here, the maintainer scripts of shim-signed and
# grub-efi-<arch> keep that copy updated as well. grub-install takes the target, the ESP
# and the id (GRUB_DISTRIBUTOR: debian) from the system, so nothing here names an
# architecture. Only where the path is free or holds patina's shim already: on a
# partition shared with another system the loader there is that system's (Windows and
# CachyOS keep one), so it stays, and the setting is off, or every update of shim and
# GRUB would replace it. A script, not the step's command: Calamares takes every $name
# in a command for one of its own variables and refuses to run it (0.1.0-alpha.10).
esp="$1/boot/efi"
[[ -d /sys/firmware/efi ]] || exit 0
other=no
while IFS= read -r f; do
  cmp -s "$f" "$esp"/EFI/debian/shim*.efi || other=yes
done < <(find "$esp/EFI/BOOT" -maxdepth 1 -iname 'boot*.efi' 2> /dev/null)
if [[ "$other" == yes ]]; then
  echo "patina grub2/force_efi_extra_removable boolean false" | chroot "$1" debconf-set-selections
else
  echo "patina grub2/force_efi_extra_removable boolean true" | chroot "$1" debconf-set-selections
  chroot "$1" grub-install --force-extra-removable --no-nvram
fi
