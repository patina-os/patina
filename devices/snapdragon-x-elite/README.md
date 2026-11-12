# Snapdragon X Elite laptops

The first ARM laptops on the roadmap (Phase 4). Debian runs on them with caveats, from
Debian's own kernel and firmware packages, so the entry exists, and patina's arm64
image has a boot menu entry for the models Debian has the firmware of; nobody has run
patina on one yet, so the status is untested. `device.yaml` holds the facts, `docs/hardware.md`
records results. The reference is Debian's own page for the ThinkPad T14s Gen 6:
<https://wiki.debian.org/InstallingDebianOn/Thinkpad/T14s_Gen6_Snapdragon>.

## What is different from a PC

- No usable ACPI tables and no device-tree partition: the boot loader must load the
  model's device tree (`models` in `device.yaml`) and pass it to the kernel. Debian's
  installer does not do that. patina's arm64 image does, for the models with `menu`
  (November 2026, a decision of the maintainer's): its boot menu has an entry per
  model, and the installer writes the files below to the disk.
- Debian 13's release kernel (6.12) is older than the laptop support upstream, so the
  arm64 image takes its kernel from `trixie-backports` (7.2 at the time of writing),
  as the Debian wiki does; the device trees come with that kernel under
  `/usr/lib/linux-image-<version>-arm64/qcom/`.
- The kernel needs `clk_ignore_unused deferred_probe_timeout=30` on its command line
  (`kernel_params` in `device.yaml`).
- Firmware for the SoC is per model. Debian 13's `firmware-qcom-soc` carries the
  ThinkPad T14s Gen 6 and the Yoga Slim 7x, and the arm64 image has it; for the other
  models the blobs live on the Windows partition. The devices rules allow a helper
  that copies them from the user's own machine, but it is written only after a run
  shows exactly which files are missing.
- Secure Boot must be off: GRUB loads no device tree while it is on.
- Everything that works upstream works from Debian's archive. Bluetooth and the camera
  need an out-of-tree kernel branch, which patina will never ship (no own kernel, no
  out-of-tree modules): they wait for upstream.

## What patina writes on these laptops

`system/`, written by the installer before the first boot and by `patina install` on a
detected laptop (`detect_compatible`: the SoC's name in the device tree):

- `grub.d/09_patina-devicetree`: GRUB loads the device tree `/etc/kernel/devicetree`
  names, the newest kernel's copy, before its menu. The installer writes that name
  from the boot menu's entry; on a system installed by hand, you do.
- `default/grub.d/patina-snapdragon-x-elite.cfg`: the kernel parameters, on every entry.
- `initramfs-tools/conf.d/zz-patina-snapdragon-x-elite.conf`: Debian's full initramfs
  in place of patina's small one, which may miss a driver the disk depends on here; a
  precaution until a run has tried the small one.

## Which model

On a ThinkPad, the machine type is the first four characters of the product number on
the sticker underneath, and Windows' System Information shows it as the System Model.

- 21N1 or 21N2 is the T14s Gen 6 with a Snapdragon X Elite. Its 1920x1200 screen is an
  LCD (`qcom/x1e78100-lenovo-thinkpad-t14s.dtb`), its 2880x1800 screen an OLED
  (`qcom/x1e78100-lenovo-thinkpad-t14s-oled.dtb`): Windows' display settings show the
  resolution.
- The T14s Gen 7 has a Snapdragon X2 Elite, which waits for upstream
  (`docs/hardware.md`): stop here.

## The run

`docs/x-elite-run.md` is the run, step by step, on a ThinkPad T14s Gen 6 with Windows
kept: the arm64 image on a USB stick, its entry for the model, the installer into a
partition Windows made room for, then the checks. Nobody has booted the image on one
of these laptops yet, so the same page keeps the way by hand for a stick that does not
get there: Debian 13 written with debootstrap from a helper stick, as the Debian wiki
has it. Same rule as the Raspberry Pi 4: a clean install per attempt, correctness over
UX.

## Known caveats to expect

- Suspend works but drains the battery within a day.
- Shutdown with the charger connected rebooted instead on the T14s Gen 6 until firmware
  2.29; update the UEFI firmware first.
- With an encrypted root, `deferred_probe_timeout=30` gives the passphrase 30 seconds;
  typed later, some devices fail to start (#1151632).
- Debian bugs worth reading before a run: #1134104 (USB on the T14s's right side, fixed
  from kernel 7.0, so in the backports kernel), #1138699 (systemd-boot and the kernel's
  64 KiB alignment), #1139313 (random crashes).
- Secure Boot is not covered by the wiki, and GRUB refuses to load a device tree while
  it is on; a signed way to hand one over is upstream's and Debian's work to come.
- GRUB loads one device tree for every entry of its menu, the newest kernel's, so an
  older kernel picked from the menu boots with the newer tree.
