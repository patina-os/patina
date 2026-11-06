#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Put the boot loader on an EFI system partition with room, or stop the install at its start.
set -euo pipefail

# Runs on the live system right after Calamares mounted the target, before anything is
# copied (shellprocess-efi-space.conf), with the target's root as $1. Debian's signed
# boot chain (shim, GRUB, MokManager) and its copy at the removable path take about
# 10 MB, and the updates of shim and GRUB write a new file before they remove the old
# one: 20 MB, of which what an earlier patina or Debian left in EFI/debian counts, as it
# is replaced. grub-install alone found a full one at the end, after an hour of
# downloads: a disk shared with Windows and CachyOS. Calamares shows what this prints
# when it fails.
#
# The partitions page takes the disk's first EFI partition when there are several, and
# on that disk the first was Windows' 260 MB one, full, while CachyOS's beside it was
# empty (November 2026). So when the one picked has no room, the next one on the disk
# patina goes to that has room is mounted at /boot/efi in its place; the boot loader
# step uses whatever is mounted there, and shellprocess-efi-fstab.conf writes it into
# fstab, where Calamares wrote the one picked. Its files stay as they are.
esp="$1/boot/efi"
[[ -d /sys/firmware/efi ]] || exit 0   # a machine started without UEFI has no such partition
if ! mountpoint -q "$esp"; then
  echo "No EFI system partition is set to be mounted at /boot/efi, so the boot loader would have nowhere to go."
  echo "Go back to the partitions page and pick the EFI system partition for /boot/efi. Nothing has been copied yet."
  exit 1
fi
need=20480
picked=$(findmnt -no SOURCE "$esp")
# The disk patina's root is on, through LUKS or LVM where there are any.
disk=$(lsblk -nspo PATH,TYPE "$(findmnt -nvo SOURCE "$1")" | awk '$2 == "disk" { print $1; exit }')
others=$(lsblk -nrpo PATH,PARTTYPE,FSTYPE "$disk" | awk -v picked="$picked" '$1 != picked && $3 == "vfat" \
  && (tolower($2) == "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" || tolower($2) == "0xef") { print $1 }')
probe=/run/patina-efi-probe
for part in "$picked" $others; do
  dir="$esp"
  if [[ "$part" != "$picked" ]]; then
    dir="$probe"
    mkdir -p "$dir"
    mount -t vfat -o ro "$part" "$dir" 2> /dev/null || continue
  fi
  free=$(df -Pk "$dir" | awk 'NR == 2 { print $4 }')
  ours=$(du -sk "$dir/EFI/debian" 2> /dev/null | cut -f 1) || ours=0
  room=$(( free + ${ours:-0} ))
  [[ "$part" == "$picked" ]] && picked_room="$room"
  [[ "$dir" == "$probe" ]] && umount "$dir"
  if (( room >= need )); then
    if [[ "$part" != "$picked" ]]; then
      umount "$esp"
      mount -t vfat -o umask=0077 "$part" "$esp"
      echo "The EFI system partition $picked has $(( picked_room / 1024 )) MB free; patina's boot loader goes to $part, which has $(( room / 1024 )) MB."
    fi
    exit 0
  fi
done
echo "The EFI system partition ($picked) has $(( picked_room / 1024 )) MB free; patina's boot loader needs $(( need / 1024 )) MB there${others:+, and no other EFI partition on the disk has that much}."
echo "Make room on it from the other system (old kernels or boot images), or install patina on a disk of its own. Nothing has been copied yet."
exit 1
