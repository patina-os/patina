# The X Elite run

The first run of patina on a Snapdragon X Elite laptop (roadmap, Phase 4): a ThinkPad
T14s Gen 6, with Windows kept beside it. patina's arm64 image has a boot menu entry for
the laptop, which loads its device tree, and its installer writes what the installed
system needs to boot the same way; nobody has started it on one yet, so this run is
the test, and each step says what to note where it stops. The background is in
`devices/snapdragon-x-elite/README.md`. Tick the boxes in a copy of this file or in a
test report (New issue, "Test report", machine "real hardware, aarch64"); what fails
goes back into `devices/snapdragon-x-elite/` and `iso/`.

You need the laptop, a USB stick of 2 GB or more, Wi-Fi and an afternoon. Keep the
speaker volume low throughout: upstream has no speaker protection yet.

## 1. The laptop

- [ ] the machine type, the first four characters of the product number underneath or
  the System Model in Windows' System Information, is 21N1 or 21N2. A T14s Gen 7 has a
  Snapdragon X2 Elite, which waits for upstream: stop here
- [ ] the screen, from Windows' display settings: 1920x1200 is the LCD, 2880x1800 the
  OLED; note which, and the memory size

## 2. In Windows

- [ ] the UEFI firmware is N42ET99W (2.29) or later: `(Get-CimInstance
  Win32_BIOS).SMBIOSBIOSVersion` in PowerShell; else update it with Lenovo's updater
  from its support site. Older versions reboot instead of shutting down on the charger
- [ ] the BitLocker recovery key is written down: `manage-bde -protectors -get C:` in
  an administrator's terminal. Windows asks for it once Secure Boot changes
- [ ] Fast Startup is off: `powercfg /h off` in an administrator's terminal
- [ ] Disk Management has shrunk C: by at least 50 GB and made a new simple volume in
  the freed space, for the installer to replace; note its size
- [ ] in the UEFI setup (F1 at power-on), Secure Boot is off: GRUB loads no device
  tree while it is on

## 3. The stick

- [ ] the arm64 image: `patina-arm64.hybrid.iso` of the newest release
  (`v0.1.0-alpha.15` or later), and `sha256sum -c --ignore-missing SHA256SUMS` beside
  it says `OK`; for a fix not yet released, the `patina-arm64` artifact of the `iso`
  workflow's latest run on `main` (GitHub, Actions; a zip with the image in it)
- [ ] written to the stick with Rufus (DD image mode when it asks) or `dd`
- [ ] the stick boots from the F12 menu, in a USB-C port on the left if another port
  does not find it

## 4. The boot menu

- [ ] patina's menu shows, and "Install on ThinkPad T14s Gen 6 (LCD)" and "(OLED)" lead
  it. If they do not, they are under "Snapdragon X Elite laptops...": note the product
  name the firmware reports (`c` for GRUB's command line, then
  `smbios --type 1 --get-string 5`, Esc to go back)
- [ ] the entry of your screen starts the installer: the boot splash or the kernel's
  lines, then the Wi-Fi step or the installer's welcome page. A screen that stays
  black for two minutes: turn the laptop off, try the other screen's entry, then the
  USB ports of the other side, and note which combination got how far
- [ ] the keyboard, the touchpad and Wi-Fi work in the installer

If no combination reaches the installer, the run goes on by hand (the last section),
and the report says where the stick stopped.

## 5. The installer

- [ ] on the disk page, "Replace a partition", and the volume of step 2, by its size;
  never "Erase disk", which is preselected and takes Windows with it. The page names
  Windows' EFI System partition as the boot loader's place
- [ ] the other pages as you like (the agent page: none, unless you test an agent);
  the install ends without an error; restart, the stick out

## 6. The first boot

- [ ] patina's boot menu lists patina and Windows Boot Manager, and waits five seconds;
  Windows starts from it (with the BitLocker key once)
- [ ] patina starts: the first-boot step on the console asks for your password, runs
  `patina install` and ends at the login screen (`docs/vm-run.md`, step 2b, has what
  to expect)
- [ ] `cat /proc/cmdline` has `clk_ignore_unused deferred_probe_timeout=30`,
  `uname -r` is 7.2 or later, `cat /etc/kernel/devicetree` names your model's tree,
  and `patina doctor` names the device (Snapdragon X Elite laptops)
- [ ] `journalctl -b -p err > ~/errors.txt`, kept for the report

## 7. The hardware

- [ ] the internal screen, keyboard with its special keys, touchpad, TrackPoint, and
  Wi-Fi from Plasma's network applet
- [ ] the USB ports on both sides, an external screen over USB-C or HDMI, sound (low),
  the battery level, a suspend and resume, a shutdown on the charger that switches off

## 8. patina

Steps 5 to 11 of `docs/vm-run.md`, as they are, with these differences:

- step 6: the initramfs is not smaller here: the laptop keeps Debian's full one
  (`devices/snapdragon-x-elite/README.md` says why). The boot menu waits five seconds,
  since Windows is beside it
- step 8, the agents bundle: note any app that has no arm64 build
- a crash in `git` may be Debian bug #1139313; note it and run the step again

## 9. The report

- [ ] a test report on GitHub: the model and screen, the memory, the UEFI version
  (`sudo dmidecode -s bios-version`), `uname -r`, the image (the release, or the
  workflow run's number), which boot menu entry and USB port, what failed, and
  `~/errors.txt`
- [ ] the output of `cat /sys/class/dmi/id/{sys_vendor,product_name,product_version,product_family}`
- [ ] a row in `docs/hardware.md`, and the status in
  `devices/snapdragon-x-elite/device.yaml`

To give the space back to Windows: put Windows Boot Manager first in the UEFI setup's
boot order and delete patina's partition in Disk Management.

## By hand, if the stick does not get there

Debian 13 written with debootstrap, as the Debian wiki's page for the T14s Gen 6 has
it, with systemd-boot, whose kernel-install hands the kernel the device tree. Leave the
volume of step 2 out, or delete it in Disk Management first: the commands below take
unallocated space.

### The helper stick

No Debian stick boots this laptop yet, so a borrowed live system is the tool that
writes Debian to the disk: Ubuntu's, which boots the T14s Gen 6 (Ubuntu's FAQ for the
Snapdragon X Elite lists it). Ubuntu is neither installed nor tested: it runs from the
stick, and what ends up on the disk is Debian alone.

- [ ] Ubuntu's arm64 desktop image (26.04 LTS or later), written to the stick with
  Rufus or `dd`
- [ ] the stick boots from the F12 menu, in a USB-C port on the left if another port
  does not find it; "Try Ubuntu" (never "Install Ubuntu"), then Wi-Fi and a terminal

### Debian

As root in the helper stick's terminal. Look at the disk first:

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
from the helper stick's system, first in the boot order:

```sh
efibootmgr --create --disk "$DISK" --part "${ESP##*p}" --label "Linux Boot Manager" \
  --loader '\EFI\systemd\systemd-bootaa64.efi'
umount -R /mnt
reboot
```

(If `umount` says the target is busy, reboot all the same.) Take the stick out.
systemd-boot's menu then lists Debian and Windows Boot Manager. From there: the checks
of step 7, Path A (steps 3 and 4 of `docs/vm-run.md`), then steps 8 and 9. There is no
GRUB on this system, so its lines do not apply: `quiet splash` in `/etc/kernel/cmdline`
is what shows the boot splash.
