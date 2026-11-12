#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Give the new system the boot files of the device whose boot menu entry started the installer.
set -euo pipefail

# Runs on the live system before the initramfs and GRUB's menu are made
# (shellprocess-device.conf), with the target's root as $1. A laptop whose firmware has
# no ACPI tables Linux can use boots only when the boot loader hands the kernel its
# device tree: the image's menu has an entry per such model (iso/live/build.sh, from
# `menu` in devices/<slug>/device.yaml), which names the device and the tree on the
# kernel's command line. The new system gets the device's system files, the ones
# `patina install` writes on that device (devices/<slug>/system/, here beside the
# installer's configuration), and the tree's name in /etc/kernel/devicetree, where
# they read it. The one step Path A cannot do first: without these files the new
# system does not reach its first boot, where Path A runs. Any other machine: nothing.
device=""
tree=""
read -ra words < /proc/cmdline
for word in "${words[@]}"; do
  case "$word" in
    patina.device=*) device="${word#*=}" ;;
    patina.devicetree=*) tree="${word#*=}" ;;
  esac
done
[[ -n "$device" ]] || exit 0
if [[ ! "$device" =~ ^[a-z0-9-]+$ || ! "$tree" =~ ^[A-Za-z0-9._/-]+\.dtb$ || "$tree" == *..* ]]; then
  echo "device-boot: cannot read the device ('$device') or its tree ('$tree')" >&2
  exit 1
fi
files="/etc/calamares/devices/$device"
[[ -d "$files" ]] || { echo "device-boot: the image has no files for $device" >&2; exit 1; }
cp -a "$files/." "$1/etc/"
install -d -m 0755 "$1/etc/kernel"
echo "$tree" > "$1/etc/kernel/devicetree"
