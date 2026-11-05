#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Stop the install at its start when the EFI system partition has no room for the boot loader.
set -euo pipefail

# Runs on the live system right after Calamares mounted the target, before anything is
# copied (shellprocess-efi-space.conf), with the target's root as $1. Debian's signed
# boot chain (shim, GRUB, MokManager) and its copy at the removable path take about
# 10 MB, and the updates of shim and GRUB write a new file before they remove the old
# one: 20 MB, of which what an earlier patina or Debian left in EFI/debian counts, as it
# is replaced. grub-install alone found a full one at the end, after an hour of
# downloads: a disk shared with Windows and CachyOS, whose systemd-boot keeps its
# kernels on that partition. Calamares shows what this prints when it fails.
esp="$1/boot/efi"
[[ -d /sys/firmware/efi ]] || exit 0   # a machine started without UEFI has no such partition
if ! mountpoint -q "$esp"; then
  echo "No EFI system partition is set to be mounted at /boot/efi, so the boot loader would have nowhere to go."
  echo "Go back to the partitions page and pick the EFI system partition for /boot/efi. Nothing has been copied yet."
  exit 1
fi
free=$(df -Pk "$esp" | awk 'NR == 2 { print $4 }')
ours=$(du -sk "$esp/EFI/debian" 2> /dev/null | cut -f 1) || ours=0
need=20480
if (( free + ${ours:-0} < need )); then
  echo "The EFI system partition ($(findmnt -no SOURCE "$esp")) has $(( (free + ${ours:-0}) / 1024 )) MB free; patina's boot loader needs $(( need / 1024 )) MB there."
  echo "Make room on it from the other system (old kernels or boot images), or install patina on a disk of its own. Nothing has been copied yet."
  exit 1
fi
