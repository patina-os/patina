# The X Elite run

The first run of patina on a Snapdragon X Elite laptop (roadmap, Phase 4): a ThinkPad
T14s Gen 6, with Windows kept beside Debian. Neither Debian's installer nor patina's
image boots these laptops, so Debian goes on by hand from a USB stick, following the
Debian wiki's page for the T14s Gen 6, and Path A follows as in `docs/vm-run.md`. The
background is in `devices/snapdragon-x-elite/README.md`. Tick the boxes in a copy of
this file or in a test report (New issue, "Test report", machine "real hardware,
aarch64"); what fails goes back into `devices/snapdragon-x-elite/`.

You need the laptop, a USB stick of 8 GB or more, Wi-Fi and an afternoon. Keep the
speaker volume low throughout: upstream has no speaker protection yet.

## 1. The laptop

- [ ] the machine type, the first four characters of the product number underneath or
  the System Model in Windows' System Information, is 21N1 or 21N2. A T14s Gen 7 has a
  Snapdragon X2 Elite, which waits for upstream: stop here
- [ ] the screen, from Windows' display settings: 1920x1200 is the LCD
  (`qcom/x1e78100-lenovo-thinkpad-t14s.dtb`), 2880x1800 the OLED
  (`qcom/x1e78100-lenovo-thinkpad-t14s-oled.dtb`); note which, and the memory size

## 2. In Windows

- [ ] the UEFI firmware is N42ET99W (2.29) or later: `(Get-CimInstance
  Win32_BIOS).SMBIOSBIOSVersion` in PowerShell; else update it with Lenovo's updater
  from its support site. Older versions reboot instead of shutting down on the charger
- [ ] the BitLocker recovery key is written down: `manage-bde -protectors -get C:` in
  an administrator's terminal. Windows asks for it once Secure Boot changes
- [ ] Fast Startup is off: `powercfg /h off` in an administrator's terminal
- [ ] Disk Management has shrunk C: by at least 50 GB, the space left unallocated
- [ ] in the UEFI setup (F1 at power-on), Secure Boot is off

## 3. The USB stick

The stick runs Ubuntu's live system, which boots the T14s Gen 6 (Ubuntu's FAQ for the
Snapdragon X Elite lists it), only as the tool that writes Debian; nothing of Ubuntu
stays on the disk.

- [ ] Ubuntu's arm64 desktop image (26.04 LTS or later), written to the stick with
  Rufus or `dd`
- [ ] the stick boots from the F12 menu, in a USB-C port on the left if another port
  does not find it; "Try Ubuntu", then Wi-Fi and a terminal

## 4. Debian

As root in the live system's terminal. Look at the disk first:

```sh
sudo -i
apt update && apt install -y debootstrap debian-archive-keyring gdisk efibootmgr
lsblk -o NAME,SIZE,FSTYPE,PARTTYPENAME,LABEL /dev/nvme0n1
sgdisk -p /dev/nvme0n1
```

- [ ] the disk is `nvme0n1`, the unallocated space is 50 GB or more, and the EFI
  System partition (about 260 MB, usually `nvme0n1p1`) goes into `ESP` below

The partitions: 1 GiB for the kernels (XBOOTLDR, since Windows' EFI partition is too
small for them beside its own files) and the rest for Debian. `sgdisk` puts both into
the largest free space, the one Windows left:

```sh
DISK=/dev/nvme0n1
ESP=/dev/nvme0n1p1
DTB=qcom/x1e78100-lenovo-thinkpad-t14s.dtb   # qcom/x1e78100-lenovo-thinkpad-t14s-oled.dtb for the OLED
sgdisk -n 0:0:+1G -t 0:ea00 -c 0:patina-boot "$DISK"
sgdisk -n 0:0:0 -t 0:8305 -c 0:patina-root "$DISK"
udevadm settle
BOOT=/dev/disk/by-partlabel/patina-boot
ROOT=/dev/disk/by-partlabel/patina-root
mkfs.vfat -F 32 -n BOOT "$BOOT"
mkfs.ext4 -L debian "$ROOT"
mount "$ROOT" /mnt && mkdir -p /mnt/boot /mnt/efi
mount "$BOOT" /mnt/boot && mount "$ESP" /mnt/efi
```

Debian 13, its sources with `trixie-backports`, and the boot set up before the kernel
comes: systemd's kernel-install reads the device tree and the command line from
`/etc/kernel/` at every kernel install and update.

```sh
debootstrap --arch=arm64 --components=main,non-free-firmware --include=ca-certificates \
  --keyring=/usr/share/keyrings/debian-archive-keyring.gpg trixie /mnt https://deb.debian.org/debian
rm -f /mnt/etc/apt/sources.list
cat > /mnt/etc/apt/sources.list.d/debian.sources << 'EOF'
Types: deb
URIs: https://deb.debian.org/debian
Suites: trixie trixie-updates trixie-backports
Components: main non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://security.debian.org/debian-security
Suites: trixie-security
Components: main non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
cat > /mnt/etc/fstab << EOF
UUID=$(blkid -s UUID -o value "$ROOT") / ext4 errors=remount-ro 0 1
UUID=$(blkid -s UUID -o value "$BOOT") /boot vfat umask=0077 0 2
UUID=$(blkid -s UUID -o value "$ESP") /efi vfat umask=0077 0 2
EOF
echo patina-t14s > /mnt/etc/hostname
printf '127.0.0.1 localhost\n127.0.1.1 patina-t14s\n' > /mnt/etc/hosts
mkdir -p /mnt/etc/kernel
echo "$DTB" > /mnt/etc/kernel/devicetree
echo "root=UUID=$(blkid -s UUID -o value "$ROOT") rw clk_ignore_unused deferred_probe_timeout=30 quiet splash" \
  > /mnt/etc/kernel/cmdline
for d in dev proc sys run; do mount --rbind "/$d" "/mnt/$d" && mount --make-rslave "/mnt/$d"; done
chroot /mnt /bin/bash
```

Inside Debian: systemd-boot with a menu of three seconds, the kernel and firmware from
`trixie-backports`, the desktop Path A assumes, and your user (pick a name):

```sh
apt update
apt install -y locales console-setup sudo systemd-boot
dpkg-reconfigure locales tzdata keyboard-configuration
bootctl install
echo 'timeout 3' >> /efi/loader/loader.conf
apt install -y -t trixie-backports linux-image-arm64 firmware-qcom-soc firmware-atheros
apt install -y kde-plasma-desktop sddm kwin-wayland plasma-nm plasma-pa pipewire-audio \
  kscreen powerdevil xdg-desktop-portal-kde git curl
adduser <name> && adduser <name> sudo
grep -H devicetree /boot/loader/entries/*.conf
exit
```

- [ ] the kernel is 7.2 or later, and the last `grep` shows a `devicetree` line with the
  model's file

`bootctl` writes no boot entry into the firmware from inside a chroot, so it is made
from the live system, first in the boot order:

```sh
efibootmgr --create --disk "$DISK" --part "${ESP##*p}" --label "Linux Boot Manager" \
  --loader '\EFI\systemd\systemd-bootaa64.efi'
umount -R /mnt
reboot
```

(If `umount` says the target is busy, reboot all the same.) Take the stick out, and keep
it for step 7.

## 5. The first boot

- [ ] systemd-boot's menu lists Debian and Windows Boot Manager; Windows starts from it
  (with the BitLocker key once)
- [ ] Debian reaches the login screen; `cat /proc/cmdline` has the parameters,
  `uname -r` the backports kernel
- [ ] the internal screen, keyboard with its special keys, touchpad, TrackPoint, and
  Wi-Fi from Plasma's network applet
- [ ] the USB ports on both sides, an external screen over USB-C or HDMI, sound (low),
  the battery level, a suspend and resume, a shutdown on the charger that switches off
- [ ] `journalctl -b -p err > ~/errors-debian.txt`, kept for the report

## 6. patina

Steps 3 to 11 of `docs/vm-run.md`, as they are, with these differences:

- step 4: `git` and `curl` are already there. A crash in `git` may be Debian bug
  #1139313; note it and run the step again
- step 6: there is no GRUB, so its line does not apply. Instead: the boot splash shows
  at the next boot (the `quiet splash` of `/etc/kernel/cmdline`), and the laptop still
  boots with the smaller initramfs (`MODULES=dep`); if it does not, step 7
- step 8, the agents bundle: note any app that has no arm64 build

## 7. If Debian stops booting

patina's initramfs takes only the modules the root's devices need, which on a
device-tree laptop may miss a driver the disk depends on. Boot the stick again, then:

```sh
sudo -i
mount /dev/disk/by-partlabel/patina-root /mnt
mount /dev/disk/by-partlabel/patina-boot /mnt/boot
mount /dev/nvme0n1p1 /mnt/efi   # the EFI System partition of step 4
for d in dev proc sys run; do mount --rbind "/$d" "/mnt/$d" && mount --make-rslave "/mnt/$d"; done
chroot /mnt sh -c 'echo MODULES=most > /etc/initramfs-tools/conf.d/zz-x-elite.conf && update-initramfs -u -k all'
```

- [ ] Debian boots again; note it in the report, since `devices/snapdragon-x-elite/`
  then needs that file as data

To give the space back to Windows: put Windows Boot Manager first in the UEFI setup's
boot order and delete the two `patina-` partitions in Disk Management.

## 8. The report

- [ ] a test report on GitHub: the model and screen, the memory, the UEFI version
  (`sudo dmidecode -s bios-version`), `uname -r`, the Ubuntu image that ran
  debootstrap, what failed, and `~/errors-debian.txt`
- [ ] the output of `cat /sys/class/dmi/id/{sys_vendor,product_name,product_version,product_family}`,
  from which patina can learn to detect the laptop
- [ ] a row in `docs/hardware.md`, and the status in
  `devices/snapdragon-x-elite/device.yaml`
