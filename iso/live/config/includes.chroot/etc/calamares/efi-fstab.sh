#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Name the EFI system partition mounted at /boot/efi in the new system's fstab.
set -euo pipefail

# Runs on the live system right after the fstab step (shellprocess-efi-fstab.conf), with
# the target's root as $1. Calamares writes the EFI partition the partitions page
# picked, and efi-space.sh mounts another one in its place when that one has no room
# for the boot loader; Debian's updates of shim and GRUB go to the partition fstab
# names. Where nothing was swapped, the entry is right already and stays as it is.
esp="$1/boot/efi"
fstab="$1/etc/fstab"
if [[ ! -d /sys/firmware/efi ]] || ! mountpoint -q "$esp"; then exit 0; fi
uuid=$(findmnt -no UUID "$esp")
[[ -n "$uuid" ]] || exit 0
if grep -Eq '^[^#[:space:]]+[[:space:]]+/boot/efi[[:space:]]' "$fstab" \
  && ! grep -Eq "^UUID=${uuid}[[:space:]]+/boot/efi[[:space:]]" "$fstab"; then
  sed -Ei "s|^[^#[:space:]]+([[:space:]]+/boot/efi[[:space:]])|UUID=$uuid\1|" "$fstab"
fi
