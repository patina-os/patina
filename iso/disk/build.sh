#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Build Try patina's disk image: the system patina's installer leaves on a disk, without an account.
set -euo pipefail
# For TryPatina.exe (patina-os/win-emulator, devices/try-patina-windows/): Debian with
# Plasma and the base packages, the same lists the image and its installer use
# (iso/live/), the first boot armed, and the step that sets the account up from Windows.
# Without firmware and microcode, which a virtual machine has no hardware for. The disk
# is 128 GiB, the launcher's ceiling, and costs only what is written; the result is a
# compressed qcow2 the launcher boots as it is. Needs root and loop devices (a
# privileged container will do), debootstrap, sfdisk, mkfs.vfat, mtools, qemu-img and the
# Go yq; see iso/README.md.
umask 022
here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
arch="${1:-amd64}"
out="${2:-$repo/iso/build/disk}"
mirror="${PATINA_DISK_MIRROR:-http://deb.debian.org/debian/}"
# The base and its archive areas, as iso/live/auto/config builds the live system.
suite=trixie
modules="$repo/iso/live/config/includes.chroot/etc/calamares/modules"
[[ -r "$repo/iso/live/arch/$arch.list.chroot" ]] \
  || { echo "disk/build.sh: no package list for '$arch' in iso/live/arch/" >&2; exit 64; }
for tool in debootstrap sfdisk losetup mkfs.vfat mcopy mkfs.ext4 blkid qemu-img yq; do
  command -v "$tool" > /dev/null || { echo "disk/build.sh: $tool missing" >&2; exit 69; }
done
yq --version 2>&1 | grep -q mikefarah || { echo "disk/build.sh: yq is not the Go yq" >&2; exit 69; }
[[ "$(id -u)" -eq 0 ]] || { echo "disk/build.sh: run as root; debootstrap and losetup need it" >&2; exit 77; }

say() { printf 'disk/build.sh: %s\n' "$*"; }
in_root() { chroot "$root" /usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C.UTF-8 "$@"; }

rm -rf --one-file-system "$out"
mkdir -p "$out"
raw="$out/disk.raw"
root="$out/root"
loops=()
cleanup() {
  if mountpoint -q "$root"; then
    umount -R "$root"
  fi
  local dev
  for dev in "${loops[@]}"; do
    losetup -d "$dev"
  done
}
trap cleanup EXIT

# The packages: the live system's list without what the installer removes, this
# architecture's list, what the installer installs, and the kernel live-build adds.
mapfile -t removed < <(yq eval '.operations[] | select(has("remove")) | .remove[]' "$modules/packages.conf")
packages=("linux-image-$arch")
while read -r name _; do
  [[ -n "$name" && "$name" != \#* ]] || continue
  case " ${removed[*]} " in *" $name "*) continue ;; esac
  case "$name" in firmware-* | *-microcode) continue ;; esac
  packages+=("$name")
done < <(cat "$repo/iso/live/config/package-lists/live.list.chroot" "$repo/iso/live/arch/$arch.list.chroot")
while read -r name; do
  case "$name" in firmware-* | *-microcode) continue ;; esac
  packages+=("$name")
done < <(yq eval '.operations[] | select(has("install")) | .install[]' "$modules/packages.conf")

# The disk: an EFI system partition of the installer's size and the rest for the system,
# ext4 as the installer's default, no swap partition (zram is one of the packages).
say "partitioning a sparse 128 GiB disk"
truncate -s 128G "$raw"
sfdisk --quiet "$raw" <<TABLE
label: gpt
size=$(yq eval '.efi.recommendedSize' "$modules/partition.conf"), type=U, name="EFI system partition"
type=L, name="patina"
TABLE
# A loop device per partition, at its offset: no partition scan, so this works where
# the kernel or a container does not show partitions of loop devices.
part() {
  local field="$1" number="$2"
  sfdisk --json "$raw" | yq -p json eval ".partitiontable.partitions[$number].$field * 512"
}
efi_dev="$(losetup --find --show --offset "$(part start 0)" --sizelimit "$(part size 0)" "$raw")"
loops+=("$efi_dev")
root_dev="$(losetup --find --show --offset "$(part start 1)" --sizelimit "$(part size 1)" "$raw")"
loops+=("$root_dev")
mkfs.vfat -F 32 -n EFI "$efi_dev" > /dev/null
mkfs.ext4 -q -L patina "$root_dev"
efi_uuid="$(blkid -s UUID -o value "$efi_dev")"
root_uuid="$(blkid -s UUID -o value "$root_dev")"
mkdir -p "$root"
mount -o noinit_itable "$root_dev" "$root"

say "bootstrapping Debian $suite ($arch) from $mirror"
keyring=()
[[ ! -r /usr/share/keyrings/debian-archive-keyring.gpg ]] \
  || keyring=(--keyring=/usr/share/keyrings/debian-archive-keyring.gpg)
debootstrap --arch="$arch" --components=main,non-free-firmware "${keyring[@]}" \
  "$suite" "$root" "$mirror" > "$out/debootstrap.log" 2>&1 \
  || { tail -n 30 "$out/debootstrap.log" >&2; exit 1; }
mount --rbind /dev "$root/dev"
mount --make-rslave "$root/dev"
mount -t proc proc "$root/proc"
mount -t sysfs sysfs "$root/sys"
mount -t tmpfs tmpfs "$root/run"
# The sources an installed system has: live-build's binary mirrors, security and updates.
cat > "$root/etc/apt/sources.list" <<SOURCES
deb http://deb.debian.org/debian/ $suite main non-free-firmware
deb http://security.debian.org/ $suite-security main non-free-firmware
deb http://deb.debian.org/debian/ $suite-updates main non-free-firmware
SOURCES
# No service starts inside the build.
printf '#!/bin/sh\nexit 101\n' > "$root/usr/sbin/policy-rc.d"
chmod 0755 "$root/usr/sbin/policy-rc.d"
# The image's own language, keyboard and time zone, which the account step replaces
# with Windows' (devices/try-patina-windows/firstboot/); GRUB's maintainer scripts keep
# the removable copy (modules/shellprocess-efi-removable.conf).
in_root debconf-set-selections <<SELECTIONS
locales locales/locales_to_be_generated multiselect en_GB.UTF-8 UTF-8
locales locales/default_environment_locale select en_GB.UTF-8
keyboard-configuration keyboard-configuration/layoutcode string us
keyboard-configuration keyboard-configuration/variantcode string
patina grub2/force_efi_extra_removable boolean true
SELECTIONS

say "installing ${#packages[@]} packages"
in_root apt-get update -q > "$out/apt.log" 2>&1 || { tail -n 30 "$out/apt.log" >&2; exit 1; }
in_root apt-get install -y -q "${packages[@]}" >> "$out/apt.log" 2>&1 \
  || { tail -n 30 "$out/apt.log" >&2; exit 1; }

say "arming the first boot"
install -D -m 0755 "$repo/iso/firstboot/patina-firstboot.sh" "$root/usr/local/lib/patina/firstboot.sh"
install -D -m 0644 "$repo/iso/firstboot/patina-firstboot.service" \
  "$root/etc/systemd/system/patina-firstboot.service"
device="$repo/devices/try-patina-windows/firstboot"
install -D -m 0755 "$device/patina-vm-setup.sh" "$root/usr/local/lib/patina/vm-setup.sh"
install -D -m 0644 "$device/patina-vm-setup.service" "$root/etc/systemd/system/patina-vm-setup.service"
yq eval '.defaultGroups[] | (.name // .)' "$modules/users.conf" > "$root/usr/local/lib/patina/vm-setup-groups"
in_root systemctl enable patina-vm-setup.service patina-firstboot.service
in_root systemctl set-default graphical.target

say "writing fstab, the host name, the language and the keyboard"
cat > "$root/etc/fstab" <<FSTAB
# <file system> <mount point> <type> <options> <dump> <pass>
UUID=$root_uuid / ext4 errors=remount-ro 0 1
UUID=$efi_uuid /boot/efi vfat umask=0077 0 2
FSTAB
printf 'patina\n' > "$root/etc/hostname"
cat > "$root/etc/hosts" <<HOSTS
127.0.0.1	localhost
127.0.1.1	patina
::1	localhost ip6-localhost ip6-loopback
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
HOSTS
in_root update-locale LANG=en_GB.UTF-8
# Every machine made from the image gets its own identity at its first boot.
: > "$root/etc/machine-id"
rm -f "$root/var/lib/dbus/machine-id"

say "putting shim and GRUB on the EFI system partition"
# As the installer's GRUB step leaves them, EFI/debian and the removable path the firmware
# starts without boot entries, from Debian's signed packages and named after them (x64 on
# amd64), with a configuration that boots this kernel. GRUB cannot install itself here,
# where the disk is a loop device: the disk's first boot runs grub-install and
# update-grub on its real disk (devices/try-patina-windows/firstboot/), and Debian's
# menu and maintainer scripts take over from there.
shim="$(find "$root/usr/lib/shim" -name 'shim*.efi.signed')"
efi="${shim##*/shim}"
efi="${efi%.efi.signed}"
kernel="$(find "$root/boot" -name 'vmlinuz-*' | sort -V | tail -n 1)"
kernel="${kernel##*/vmlinuz-}"
esp="$out/esp"
mkdir -p "$esp/EFI/debian" "$esp/EFI/BOOT" "$root/boot/grub" "$root/boot/efi"
cp "$shim" "$esp/EFI/debian/shim$efi.efi"
cp "$root/usr/lib/shim/mm$efi.efi.signed" "$esp/EFI/debian/mm$efi.efi"
cp "$root"/usr/lib/grub/*-efi-signed/"grub$efi.efi.signed" "$esp/EFI/debian/grub$efi.efi"
cp "$root/usr/lib/shim/BOOT${efi^^}.CSV" "$esp/EFI/debian/"
cat > "$esp/EFI/debian/grub.cfg" <<STUB
search.fs_uuid $root_uuid root
set prefix=(\$root)'/boot/grub'
configfile \$prefix/grub.cfg
STUB
cp "$esp/EFI/debian/shim$efi.efi" "$esp/EFI/BOOT/BOOT${efi^^}.EFI"
cp "$esp/EFI/debian/mm$efi.efi" "$esp/EFI/debian/grub$efi.efi" "$esp/EFI/debian/grub.cfg" "$esp/EFI/BOOT/"
MTOOLS_SKIP_CHECK=1 mcopy -s -i "$efi_dev" "$esp/EFI" ::/
rm -rf "$esp"
cat > "$root/boot/grub/grub.cfg" <<GRUB
# Until the first boot runs update-grub (devices/try-patina-windows/firstboot/).
set timeout=0
search --no-floppy --fs-uuid --set=root $root_uuid
linux /boot/vmlinuz-$kernel root=UUID=$root_uuid ro quiet
initrd /boot/initrd.img-$kernel
GRUB
in_root update-initramfs -u -k all > /dev/null

say "cleaning up"
in_root apt-get clean
rm -rf "$root"/var/lib/apt/lists/* "$root"/tmp/* "$root/var/log/bootstrap.log"
rm -f "$root/usr/sbin/policy-rc.d" "$root/etc/resolv.conf"
cleanup
loops=()
trap - EXIT

say "compressing the image"
qemu-img convert -c -O qcow2 "$raw" "$out/patina-$arch.qcow2"
rm -f "$raw"
rm -rf "$root"
ls -l "$out/patina-$arch.qcow2"
