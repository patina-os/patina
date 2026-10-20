#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The release gate for the ISO (iso/README.md): install it unattended in QEMU, boot the
# result, and require the first-boot service to report done. Exit 0 only then.
set -euo pipefail

usage() {
  cat <<USAGE
usage: install-test.sh <patina21.iso> [work-dir]

Needs qemu-system-x86_64 or qemu-system-aarch64 (matching the ISO's architecture), the
OVMF or AAVMF firmware, bsdtar, jq, python3 and KVM. Environment:
  PATINA_TEST_ARCH      x86_64 (default) or aarch64
  PATINA_TEST_MEMORY    VM memory in MiB (default 4096)
  PATINA_TEST_TIMEOUT   seconds per phase (default 2400)
  PATINA_TEST_THEME     theme name the first boot applies (default template)
Logs land in <work-dir>/: install.log, firstboot.log.
USAGE
}

[[ $# -ge 1 ]] || { usage >&2; exit 64; }
iso="$(readlink -f "$1")"
work="${2:-$PWD/iso/build/test}"
arch="${PATINA_TEST_ARCH:-x86_64}"
memory="${PATINA_TEST_MEMORY:-4096}"
timeout_s="${PATINA_TEST_TIMEOUT:-2400}"
here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
[[ -r "$iso" ]] || { echo "install-test: cannot read $iso" >&2; exit 66; }
for tool in "qemu-system-$arch" bsdtar jq python3; do
  command -v "$tool" >/dev/null || { echo "install-test: $tool missing" >&2; exit 69; }
done

mkdir -p "$work"
disk="$work/disk.qcow2"
profile="$work/profile.json"

# The unattended profile: the preset every ISO install loads, plus the test's answers.
jq -s '.[0] * .[1]' "$here/../agama/patina21.json" "$here/answers.json" > "$profile"
# Serve it to the guest; QEMU user networking reaches the host as 10.0.2.2.
python3 -m http.server --bind 127.0.0.1 --directory "$work" 8787 >/dev/null 2>&1 &
http_pid=$!
trap 'kill "$http_pid" 2>/dev/null || true' EXIT

# Kernel and initrd straight from the ISO, so the boot options can be ours.
# KIWI places them under boot/<arch>/loader/ on live ISOs.
bsdtar -C "$work" -xf "$iso" "boot/$arch/loader/linux" "boot/$arch/loader/initrd"
volid="$(blkid -o value -s LABEL "$iso" 2>/dev/null || true)"
: "${volid:=patina21-installer}"

case "$arch" in
  x86_64)
    candidates=(/usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd
      /usr/share/edk2/ovmf/OVMF_CODE.fd)
    machine=(-machine "q35,accel=kvm" -cpu host)
    ;;
  aarch64)
    candidates=(/usr/share/AAVMF/AAVMF_CODE.fd /usr/share/qemu-efi-aarch64/QEMU_EFI.fd)
    machine=(-machine "virt,accel=kvm" -cpu host)
    ;;
  *) echo "install-test: unsupported arch $arch" >&2; exit 64 ;;
esac
firmware=""
for candidate in "${candidates[@]}"; do
  if [[ -r "$candidate" ]]; then
    firmware="$candidate"
    break
  fi
done
[[ -n "$firmware" ]] || { echo "install-test: no UEFI firmware found" >&2; exit 69; }

qemu-img create -q -f qcow2 "$disk" 40G

# Wait for a line on the serial log, or fail when the VM exits or the timeout passes.
wait_for() {
  local pattern="$1" log="$2" pid="$3" waited=0
  until grep -q -E "$pattern" "$log"; do
    if ! kill -0 "$pid" 2>/dev/null; then
      return 1
    fi
    if (( waited >= timeout_s )); then
      echo "install-test: timeout waiting for '$pattern'" >&2
      kill "$pid" 2>/dev/null || true
      return 1
    fi
    sleep 10
    waited=$((waited + 10))
  done
}

echo "install-test: phase 1, unattended install from $iso"
qemu-system-"$arch" "${machine[@]}" -m "$memory" -smp 2 -display none -no-reboot \
  -drive "if=pflash,format=raw,readonly=on,file=$firmware" \
  -drive "file=$disk,if=virtio,format=qcow2" \
  -cdrom "$iso" \
  -kernel "$work/boot/$arch/loader/linux" -initrd "$work/boot/$arch/loader/initrd" \
  -append "root=live:CDLABEL=$volid rd.live.image rd.live.overlay.overlayfs=1 console=ttyS0,115200n8 inst.auto=http://10.0.2.2:8787/profile.json inst.finish=poweroff" \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
  -serial "file:$work/install.log" &
qemu_pid=$!
# Agama prints its result on the serial console; the VM powers off afterwards.
if ! wait_for 'Installation finished|inst\.finish|reboot: Power down' "$work/install.log" "$qemu_pid"; then
  echo "install-test: install phase failed; see $work/install.log" >&2
  exit 1
fi
wait "$qemu_pid" || true
if grep -q -E 'Installation failed|ERROR.*agama' "$work/install.log"; then
  echo "install-test: Agama reported an error; see $work/install.log" >&2
  exit 1
fi

echo "install-test: phase 2, first boot of the installed system"
qemu-system-"$arch" "${machine[@]}" -m "$memory" -smp 2 -display none -no-reboot \
  -drive "if=pflash,format=raw,readonly=on,file=$firmware" \
  -drive "file=$disk,if=virtio,format=qcow2" \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
  -serial "file:$work/firstboot.log" &
qemu_pid=$!
if ! wait_for 'patina21 firstboot: done' "$work/firstboot.log" "$qemu_pid"; then
  echo "install-test: first boot did not finish; see $work/firstboot.log" >&2
  kill "$qemu_pid" 2>/dev/null || true
  exit 1
fi
kill "$qemu_pid" 2>/dev/null || true
echo "install-test: passed"
