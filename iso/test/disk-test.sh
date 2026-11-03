#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The automated part of Try patina's disk image release gate: its first boot sets the account up and starts patina's own.
set -euo pipefail

usage() {
  cat <<USAGE
usage: disk-test.sh <patina-amd64.qcow2> [work-dir]
Boots the image iso/disk/build.sh made as TryPatina.exe does: UEFI, shim and GRUB from
the image, an NVMe disk that is a copy-on-write layer over it, the product name the
device is detected by, and the answers of Try patina's setup as QEMU firmware
configuration, with a language, keyboard and time zone other than the image's own. It
passes once the account step reports on the serial port that it set the account up
with those answers. Needs qemu-system-x86_64, qemu-img and the OVMF firmware; KVM when
/dev/kvm is writable, else TCG (slower, longer default timeout). Environment:
  PATINA_TEST_MEMORY    VM memory in MiB (default 4096)
  PATINA_TEST_TIMEOUT   seconds to wait (default 600 with KVM, 2400 without)
The serial console lands in <work-dir>/disk-boot.log.
USAGE
}

[[ $# -ge 1 ]] || { usage >&2; exit 64; }
image="$(readlink -f "$1")"
work="${2:-$PWD/iso/build/disk-test}"
memory="${PATINA_TEST_MEMORY:-4096}"
[[ -r "$image" ]] || { echo "disk-test: cannot read $image" >&2; exit 66; }
for tool in qemu-system-x86_64 qemu-img; do
  command -v "$tool" > /dev/null || { echo "disk-test: $tool missing" >&2; exit 69; }
done
if [[ -w /dev/kvm ]]; then
  accel=kvm cpu=host timeout_s="${PATINA_TEST_TIMEOUT:-600}"
else
  accel=tcg cpu=max timeout_s="${PATINA_TEST_TIMEOUT:-2400}"
fi
# The firmware and an empty store of its variables beside it, as the launcher has them:
# no boot entries, so the firmware starts the removable path the image's GRUB keeps.
firmware="" vars=""
for candidate in /usr/share/OVMF/OVMF_CODE_4M.fd:/usr/share/OVMF/OVMF_VARS_4M.fd \
  /usr/share/OVMF/OVMF_CODE.fd:/usr/share/OVMF/OVMF_VARS.fd \
  /usr/share/edk2/ovmf/OVMF_CODE.fd:/usr/share/edk2/ovmf/OVMF_VARS.fd; do
  if [[ -r "${candidate%%:*}" && -r "${candidate#*:}" ]]; then
    firmware="${candidate%%:*}" vars="${candidate#*:}"
    break
  fi
done
[[ -n "$firmware" ]] || { echo "disk-test: no UEFI firmware found" >&2; exit 69; }
cpus="$(nproc)"
(( cpus > 4 )) && cpus=4

mkdir -p "$work"
log="$work/disk-boot.log"
: > "$log"
disk="$work/disk.qcow2"
rm -f "$disk"
qemu-img create -q -f qcow2 -b "$image" -F qcow2 "$disk"
cp "$vars" "$work/vars.fd"
# Answers as Try patina's setup writes them (devices/try-patina-windows/README.md), with
# a language, keyboard and time zone other than the image's own.
answers="$work/setup"
cat > "$answers" <<SETUP
PATINA_USER=tester
PATINA_FULLNAME=Try patina test
PATINA_PASSWORD=patina-test
PATINA_LOCALE=de_DE.UTF-8
PATINA_KEYBOARD_LAYOUT=de
PATINA_KEYBOARD_VARIANT=nodeadkeys
PATINA_TIMEZONE=Europe/Berlin
PATINA_AI_AGENT=none
PATINA_AI=local
PATINA_BUNDLES=minimal,
PATINA_THEME=aurora
SETUP

echo "disk-test: booting $image ($accel, ${cpus} cpus, timeout ${timeout_s}s)"
qemu-system-x86_64 -machine "q35,accel=$accel" -cpu "$cpu" -m "$memory" -smp "$cpus" \
  -display none -no-reboot -vga std \
  -smbios "type=1,product=Try patina" \
  -drive "if=pflash,format=raw,readonly=on,file=$firmware" \
  -drive "if=pflash,format=raw,file=$work/vars.fd" \
  -drive "if=none,id=disk,format=qcow2,file=$disk" -device nvme,drive=disk,serial=patina \
  -fw_cfg "name=opt/io.github.patina_os/setup,file=$answers" \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
  -serial "file:$log" &
qemu_pid=$!
trap 'kill "$qemu_pid" 2> /dev/null || true' EXIT

waited=0
until grep -q 'patina vm setup: done' "$log"; do
  if grep -q 'patina vm setup: Try patina sent no usable' "$log"; then
    echo "disk-test: the account step refused the answers; see $log" >&2
    exit 1
  fi
  if ! kill -0 "$qemu_pid" 2> /dev/null; then
    echo "disk-test: the VM exited before the account step was done; see $log" >&2
    exit 1
  fi
  if (( waited >= timeout_s )); then
    echo "disk-test: timeout after ${timeout_s}s; see $log" >&2
    exit 1
  fi
  sleep 10
  waited=$((waited + 10))
done
expected='patina vm setup: setting up tester (de_DE.UTF-8, keyboard de nodeadkeys, Europe/Berlin)'
grep -qF "$expected" "$log" \
  || { echo "disk-test: the account step did not take the answers as given; see $log" >&2; exit 1; }
echo "disk-test: passed (account set up from the answers after ${waited}s)"
