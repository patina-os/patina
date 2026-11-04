#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Try patina's disk image started twice, the second time with patina's boot splash in place: the login screen must follow it.
set -euo pipefail

usage() {
  cat <<USAGE
usage: second-boot-test.sh <patina-amd64.qcow2> [work-dir]
The start that hung in 0.1.0-alpha.7: a machine on which \`patina install\` has put its
system files and the boot splash in place starts with \`quiet splash\`, and the login
screen has to take over from the splash. On a copy of the image this writes what the
install's system step writes (defaults/system/ and the Try patina device's system/ to
/etc, the splash drawn from branding/logo.txt) and marks the first boot's Path A as
done. The first start, booted as disk-test.sh boots it, sets the account up, rebuilds
the initramfs and GRUB's menu as the install's apply step does and powers off; the
second passes once SDDM has started its greeter after the splash. Needs root (loop
devices), qemu-system-x86_64, qemu-img, the OVMF firmware, sfdisk, the Go yq and
rsvg-convert; KVM when /dev/kvm is there, else TCG (slower, longer timeouts).
Environment:
  PATINA_TEST_MEMORY    VM memory in MiB (default 4096)
  PATINA_TEST_TIMEOUT   seconds to wait for each start (default 600 with KVM, 2400 without)
The serial console lands in <work-dir>/first-start.log and <work-dir>/second-start.log.
USAGE
}

[[ $# -ge 1 ]] || { usage >&2; exit 64; }
image="$(readlink -f "$1")"
work="${2:-$PWD/iso/build/second-boot-test}"
memory="${PATINA_TEST_MEMORY:-4096}"
repo="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
[[ -r "$image" ]] || { echo "second-boot-test: cannot read $image" >&2; exit 66; }
[[ "$(id -u)" -eq 0 ]] || { echo "second-boot-test: run as root; the image is mounted" >&2; exit 77; }
for tool in qemu-system-x86_64 qemu-img sfdisk losetup yq rsvg-convert; do
  command -v "$tool" > /dev/null || { echo "second-boot-test: $tool missing" >&2; exit 69; }
done
yq --version 2>&1 | grep -q mikefarah || { echo "second-boot-test: yq is not the Go yq" >&2; exit 69; }
if [[ -e /dev/kvm ]]; then
  accel=kvm cpu=host timeout_s="${PATINA_TEST_TIMEOUT:-600}"
else
  accel=tcg cpu=max timeout_s="${PATINA_TEST_TIMEOUT:-2400}"
fi
firmware="" vars=""
for candidate in /usr/share/OVMF/OVMF_CODE_4M.fd:/usr/share/OVMF/OVMF_VARS_4M.fd \
  /usr/share/OVMF/OVMF_CODE.fd:/usr/share/OVMF/OVMF_VARS.fd \
  /usr/share/edk2/ovmf/OVMF_CODE.fd:/usr/share/edk2/ovmf/OVMF_VARS.fd; do
  if [[ -r "${candidate%%:*}" && -r "${candidate#*:}" ]]; then
    firmware="${candidate%%:*}" vars="${candidate#*:}"
    break
  fi
done
[[ -n "$firmware" ]] || { echo "second-boot-test: no UEFI firmware found" >&2; exit 69; }
cpus="$(nproc)"
(( cpus > 4 )) && cpus=4

mkdir -p "$work"
disk="$work/disk.raw"
root="$work/root"
loop="" qemu_pid=""
cleanup() {
  [[ -z "$qemu_pid" ]] || kill "$qemu_pid" 2> /dev/null || true
  if mountpoint -q "$root"; then umount "$root"; fi
  [[ -z "$loop" ]] || losetup -d "$loop"
}
trap cleanup EXIT

# A raw copy, sparse, so the system's partition can be mounted at its offset, as
# iso/disk/build.sh mounts it.
echo "second-boot-test: copying $image"
rm -f "$disk"
qemu-img convert -O raw "$image" "$disk"
offset="$(sfdisk --json "$disk" | yq -p json eval '.partitiontable.partitions[1].start * 512')"
size="$(sfdisk --json "$disk" | yq -p json eval '.partitiontable.partitions[1].size * 512')"
loop="$(losetup --find --show --offset "$offset" --sizelimit "$size" "$disk")"
mkdir -p "$root"
mount "$loop" "$root"

# What the system step of `patina install` (install_system in bin/patina-install) writes
# on Try patina: every file of defaults/system/ and of the device's system/ at the same
# path under /etc, and the boot splash.
for dir in "$repo/defaults/system" "$repo/devices/try-patina-windows/system"; do
  while IFS= read -r src; do
    install -D -m 0644 "$src" "$root/etc/${src#"$dir/"}"
  done < <(find "$dir" -type f)
done
PATINA_PATH="$repo"
# shellcheck source=bin/lib.sh
source "$repo/bin/lib.sh"
( render_boot_splash "$root/usr/share/plymouth/themes/patina" )
# The first boot's Path A counts as done; this test brings the rest of the install.
mkdir -p "$root/var/lib/patina"
date -u +%FT%TZ > "$root/var/lib/patina/firstboot-done"

# The first start: what the install's apply step runs for these files, then off.
cat > "$root/etc/systemd/system/patina-test-arm.service" <<'UNIT'
[Unit]
Description=patina test: the install's apply step for the splash, once
ConditionPathExists=!/var/lib/patina-test/armed
After=patina-vm-setup.service
Before=display-manager.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'if update-initramfs -u && update-grub; then mkdir -p /var/lib/patina-test && touch /var/lib/patina-test/armed && echo "patina test: second start armed"; else echo "patina test: arming failed"; fi > /dev/ttyS0 2>&1; systemctl poweroff'

[Install]
WantedBy=multi-user.target
UNIT
# The second start: whether the splash ran, then SDDM's greeter, on the serial port.
cat > "$root/etc/systemd/system/patina-test-probe.service" <<'UNIT'
[Unit]
Description=patina test: the login screen after the splash
ConditionPathExists=/var/lib/patina-test/armed

[Service]
ExecStart=/bin/sh -c '\
  if grep -qw splash /proc/cmdline && systemctl -q is-active plymouth-start.service; then \
    echo "patina test: the splash ran ($(plymouth-set-default-theme))"; \
  else \
    echo "patina test: no splash"; \
  fi > /dev/ttyS0; \
  while sleep 10; do \
    if journalctl -b -q -u sddm.service | grep -q "Greeter session started"; then \
      echo "patina test: login screen on VT $(fgconsole)" > /dev/ttyS0; exit 0; \
    fi; \
    echo "patina test: waiting, VT $(fgconsole), SDDM: $(journalctl -b -q -u sddm.service -n 1 -o cat)" > /dev/ttyS0; \
  done'

[Install]
WantedBy=multi-user.target
UNIT
systemctl --root="$root" --quiet enable patina-test-arm.service patina-test-probe.service
umount "$root"
losetup -d "$loop"
loop=""

answers="$work/setup"
cat > "$answers" <<SETUP
PATINA_USER=tester
PATINA_FULLNAME=Try patina test
PATINA_PASSWORD=patina-test
PATINA_LOCALE=en_GB.UTF-8
PATINA_KEYBOARD_LAYOUT=us
PATINA_TIMEZONE=Etc/UTC
PATINA_AI_AGENT=none
PATINA_AI=local
PATINA_BUNDLES=minimal,
PATINA_THEME=aurora
SETUP
cp "$vars" "$work/vars.fd"

# start <log> <pass> <fail>: boot as disk-test.sh does and wait until the serial port
# says <pass>; <fail> on it, the VM's exit or the timeout fail the test.
start() {
  local log="$1" pass="$2" fail="$3" waited=0
  : > "$log"
  qemu-system-x86_64 -machine "q35,accel=$accel" -cpu "$cpu" -m "$memory" -smp "$cpus" \
    -display none -no-reboot -vga std \
    -smbios "type=1,product=Try patina" \
    -drive "if=pflash,format=raw,readonly=on,file=$firmware" \
    -drive "if=pflash,format=raw,file=$work/vars.fd" \
    -drive "if=none,id=disk,format=raw,file=$disk" -device nvme,drive=disk,serial=patina \
    -fw_cfg "name=opt/io.github.patina_os/setup,file=$answers" \
    -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
    -serial "file:$log" &
  qemu_pid=$!
  until grep -aq "$pass" "$log"; do
    if grep -aq "$fail" "$log"; then
      echo "second-boot-test: $(grep -ao "$fail.*" "$log" | head -n 1 | tr -d '\r'); see $log" >&2
      exit 1
    fi
    if ! kill -0 "$qemu_pid" 2> /dev/null; then
      echo "second-boot-test: the VM exited early; see $log" >&2
      exit 1
    fi
    if (( waited >= timeout_s )); then
      echo "second-boot-test: timeout after ${timeout_s}s; the last word was:" >&2
      grep -a 'patina test:' "$log" | tail -n 1 | tr -d '\r' >&2
      exit 1
    fi
    sleep 10
    waited=$((waited + 10))
  done
  echo "second-boot-test: $(grep -ao "$pass.*" "$log" | head -n 1 | tr -d '\r') after ${waited}s"
}

echo "second-boot-test: first start ($accel, ${cpus} cpus, timeout ${timeout_s}s each)"
start "$work/first-start.log" 'patina test: second start armed' 'patina test: arming failed'
# It powers itself off.
for _ in $(seq 60); do
  kill -0 "$qemu_pid" 2> /dev/null || break
  sleep 5
done
if kill -0 "$qemu_pid" 2> /dev/null; then
  echo "second-boot-test: the first start did not power off; see $work/first-start.log" >&2
  exit 1
fi
qemu_pid=""
echo "second-boot-test: second start"
start "$work/second-start.log" 'patina test: login screen on VT' 'patina test: no splash'
echo "second-boot-test: passed"
