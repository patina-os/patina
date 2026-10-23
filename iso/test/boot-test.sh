#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The automated part of the image's release gate (iso/README.md): boot the live image in
# QEMU and require the installer screen to come up. Exit 0 only then. On the way out it
# takes a screenshot of that screen, the source of the installer image in docs/screenshots/.
set -euo pipefail

usage() {
  cat <<USAGE
usage: boot-test.sh <patina.iso> [work-dir]

Needs qemu-system-x86_64 or qemu-system-aarch64 (matching the image), the OVMF or
AAVMF firmware and bsdtar. KVM is used when /dev/kvm is writable; otherwise QEMU
emulates the CPU (TCG), which is slower and gets a longer default timeout. Environment:
  PATINA_TEST_ARCH      amd64 (default) or arm64
  PATINA_TEST_MEMORY    VM memory in MiB (default 4096)
  PATINA_TEST_TIMEOUT   seconds to wait for the installer (default 900 with KVM,
                        2700 without)
  PATINA_TEST_SETTLE    seconds between the installer reporting ready and the
                        screenshot, for the window to be drawn (default 30 with KVM,
                        120 without)
  PATINA_TEST_MONITOR   TCP port on localhost for QEMU's monitor (default 45454)
The serial console lands in <work-dir>/boot.log, the screenshot of the installer screen
in <work-dir>/installer-<arch>.png. The VM gets an empty 32 GiB disk (a sparse file in
<work-dir>, no space used) so the installer's requirement checks pass as on a laptop.
USAGE
}

[[ $# -ge 1 ]] || { usage >&2; exit 64; }
iso="$(readlink -f "$1")"
work="${2:-$PWD/iso/build/test}"
arch="${PATINA_TEST_ARCH:-amd64}"
memory="${PATINA_TEST_MEMORY:-4096}"
[[ -r "$iso" ]] || { echo "boot-test: cannot read $iso" >&2; exit 66; }

if [[ -w /dev/kvm ]]; then
  accel="kvm"
  cpu="host"
  timeout_s="${PATINA_TEST_TIMEOUT:-900}"
  settle_s="${PATINA_TEST_SETTLE:-30}"
else
  accel="tcg"
  cpu="max"
  timeout_s="${PATINA_TEST_TIMEOUT:-2700}"
  settle_s="${PATINA_TEST_SETTLE:-120}"
fi
monitor_port="${PATINA_TEST_MONITOR:-45454}"
cpus="$(nproc)"
(( cpus > 4 )) && cpus=4

# The display device gives X a framebuffer to start on while nothing is shown
# (-display none): a VGA card on PCs, a virtio GPU on the arm64 virt machine.
case "$arch" in
  amd64)
    qemu="qemu-system-x86_64"
    candidates=(/usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd
      /usr/share/edk2/ovmf/OVMF_CODE.fd)
    machine=(-machine "q35,accel=$accel" -cpu "$cpu" -vga std)
    serial="ttyS0"
    ;;
  arm64)
    qemu="qemu-system-aarch64"
    candidates=(/usr/share/AAVMF/AAVMF_CODE.fd /usr/share/qemu-efi-aarch64/QEMU_EFI.fd
      /usr/share/edk2/aarch64/QEMU_EFI.fd)
    machine=(-machine "virt,accel=$accel" -cpu "$cpu" -device virtio-gpu-pci)
    serial="ttyAMA0"
    ;;
  *) echo "boot-test: unsupported arch $arch" >&2; exit 64 ;;
esac
for tool in "$qemu" bsdtar; do
  command -v "$tool" > /dev/null || { echo "boot-test: $tool missing" >&2; exit 69; }
done
firmware=""
for candidate in "${candidates[@]}"; do
  if [[ -r "$candidate" ]]; then
    firmware="$candidate"
    break
  fi
done
[[ -n "$firmware" ]] || { echo "boot-test: no UEFI firmware found" >&2; exit 69; }

mkdir -p "$work"
log="$work/boot.log"
: > "$log"
screenshot="$work/installer-$arch.png"
rm -f "$screenshot"
# An empty disk, so the welcome page shows a system that can be installed rather than
# the two requirement errors of a machine without one. Sparse: it costs no space.
disk="$work/disk.raw"
rm -f "$disk"
truncate -s 32G "$disk"
# Kernel and initrd straight from the image (live-build puts them under live/, named
# after the kernel version), so the boot options can be ours: the serial console the
# test watches.
rm -rf "$work/live"
bsdtar -C "$work" -xf "$iso" 'live/vmlinuz*' 'live/initrd*'
kernel="$(find "$work/live" -name 'vmlinuz*' | sort | head -n1)"
initrd="$(find "$work/live" -name 'initrd*' | sort | head -n1)"
[[ -n "$kernel" && -n "$initrd" ]] \
  || { echo "boot-test: no kernel or initrd under live/ in $iso" >&2; exit 65; }

echo "boot-test: booting $iso ($arch, $accel, ${cpus} cpus, timeout ${timeout_s}s)"
"$qemu" "${machine[@]}" -m "$memory" -smp "$cpus" -display none -no-reboot \
  -drive "if=pflash,format=raw,readonly=on,file=$firmware" \
  -cdrom "$iso" \
  -drive "file=$disk,format=raw,if=virtio" \
  -kernel "$kernel" -initrd "$initrd" \
  -append "boot=live components quiet hostname=patina-live username=live noautologin console=$serial,115200n8" \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
  -serial "file:$log" \
  -monitor "tcp:127.0.0.1:$monitor_port,server,nowait" &
qemu_pid=$!
trap 'kill "$qemu_pid" 2>/dev/null || true' EXIT

waited=0
until grep -q 'patina installer: ready' "$log"; do
  if ! kill -0 "$qemu_pid" 2> /dev/null; then
    echo "boot-test: the VM exited before the installer came up; see $log" >&2
    exit 1
  fi
  if (( waited >= timeout_s )); then
    echo "boot-test: timeout after ${timeout_s}s; see $log" >&2
    exit 1
  fi
  sleep 10
  waited=$((waited + 10))
done
echo "boot-test: passed (installer up after ${waited}s)"

# The ready line says Calamares is running, not that its window is drawn; give it a
# moment, then ask QEMU's monitor for a screenshot of the display it keeps even without
# a window (-display none). A missing screenshot is reported but does not fail the gate.
sleep "$settle_s"
if exec 3<> "/dev/tcp/127.0.0.1/$monitor_port"; then
  printf 'screendump %s -f png\n' "$screenshot" >&3
  sleep 5
  exec 3>&-
fi
if [[ -s "$screenshot" ]]; then
  echo "boot-test: screenshot in $screenshot"
else
  echo "boot-test: no screenshot; QEMU's monitor on port $monitor_port did not deliver one" >&2
fi
