#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The automated part of the image's release gate (iso/README.md): boot the live image in
# QEMU and require the installer screen to come up. Exit 0 only then.
set -euo pipefail

usage() {
  cat <<USAGE
usage: boot-test.sh <patina21.iso> [work-dir]

Needs qemu-system-x86_64 or qemu-system-aarch64 (matching the image), the OVMF or
AAVMF firmware, bsdtar and KVM. Environment:
  PATINA_TEST_ARCH      amd64 (default) or arm64
  PATINA_TEST_MEMORY    VM memory in MiB (default 4096)
  PATINA_TEST_TIMEOUT   seconds to wait for the installer (default 900)
The serial console lands in <work-dir>/boot.log.
USAGE
}

[[ $# -ge 1 ]] || { usage >&2; exit 64; }
iso="$(readlink -f "$1")"
work="${2:-$PWD/iso/build/test}"
arch="${PATINA_TEST_ARCH:-amd64}"
memory="${PATINA_TEST_MEMORY:-4096}"
timeout_s="${PATINA_TEST_TIMEOUT:-900}"
[[ -r "$iso" ]] || { echo "boot-test: cannot read $iso" >&2; exit 66; }

case "$arch" in
  amd64)
    qemu="qemu-system-x86_64"
    candidates=(/usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd
      /usr/share/edk2/ovmf/OVMF_CODE.fd)
    machine=(-machine "q35,accel=kvm" -cpu host)
    ;;
  arm64)
    qemu="qemu-system-aarch64"
    candidates=(/usr/share/AAVMF/AAVMF_CODE.fd /usr/share/qemu-efi-aarch64/QEMU_EFI.fd)
    machine=(-machine "virt,accel=kvm" -cpu host)
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
# Kernel and initrd straight from the image (live-build puts them under live/), so the
# boot options can be ours: the serial console the test watches.
bsdtar -C "$work" -xf "$iso" live/vmlinuz live/initrd.img

echo "boot-test: booting $iso"
"$qemu" "${machine[@]}" -m "$memory" -smp 2 -display none -vga std -no-reboot \
  -drive "if=pflash,format=raw,readonly=on,file=$firmware" \
  -cdrom "$iso" \
  -kernel "$work/live/vmlinuz" -initrd "$work/live/initrd.img" \
  -append "boot=live components quiet console=ttyS0,115200n8" \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
  -serial "file:$log" &
qemu_pid=$!
trap 'kill "$qemu_pid" 2>/dev/null || true' EXIT

waited=0
until grep -q 'patina21 installer: ready' "$log"; do
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
