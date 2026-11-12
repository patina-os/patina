# Snapdragon X Elite laptops

The first ARM laptops on the roadmap (Phase 4). Debian runs on them with caveats, from
Debian's own kernel and firmware packages, so the entry exists; nobody has run patina
on one yet, so the status is untested. `device.yaml` holds the facts, `docs/hardware.md`
records results. The reference is Debian's own page for the ThinkPad T14s Gen 6:
<https://wiki.debian.org/InstallingDebianOn/Thinkpad/T14s_Gen6_Snapdragon>.

## What is different from a PC

- No usable ACPI tables and no device-tree partition: the boot loader must load the
  model's device tree (`models` in `device.yaml`) from the EFI partition and pass it to
  the kernel. Debian's installer and the patina live image do not do that, so Path B is
  not an option and Path A starts from a manual install.
- Debian 13's release kernel (6.12) is older than the laptop support upstream. The Debian
  wiki installs the kernel and firmware from `trixie-backports` (7.2 at the time of
  writing); the device trees come with that kernel under
  `/usr/lib/linux-image-<version>-arm64/qcom/`.
- The kernel needs `clk_ignore_unused deferred_probe_timeout=30` on its command line
  (`kernel_params` in `device.yaml`).
- Firmware for the SoC is per model. Debian 13's `firmware-qcom-soc` carries the
  ThinkPad T14s Gen 6 and the Yoga Slim 7x; for the other models the blobs live on the
  Windows partition. The devices rules allow a helper that copies them from the user's
  own machine, but it is written only after a run shows exactly which files are missing.
- Everything that works upstream works from Debian's archive. Bluetooth and the camera
  need an out-of-tree kernel branch, which patina will never ship (no own kernel, no
  out-of-tree modules): they wait for upstream.

## Which model

On a ThinkPad, the machine type is the first four characters of the product number on
the sticker underneath, and Windows' System Information shows it as the System Model.

- 21N1 or 21N2 is the T14s Gen 6 with a Snapdragon X Elite. Its 1920x1200 screen is an
  LCD (`x1e78100-lenovo-thinkpad-t14s.dtb`), its 2880x1800 screen an OLED
  (`x1e78100-lenovo-thinkpad-t14s-oled.dtb`): Windows' display settings show the
  resolution.
- The T14s Gen 7 has a Snapdragon X2 Elite, which waits for upstream
  (`docs/hardware.md`): stop here.

## The run

`docs/x-elite-run.md` is the run, step by step, on a ThinkPad T14s Gen 6 with Windows
kept: Debian 13 written from a helper USB stick, Ubuntu's live system as the tool
and Debian alone on the disk (debootstrap, kernel and firmware from `trixie-backports`), an XBOOTLDR partition for the kernels,
since Windows' EFI partition is too small for them, and the boot set up through
`/etc/kernel/devicetree` and `/etc/kernel/cmdline`, which systemd's kernel-install reads
at every kernel update. `quiet splash` goes there too: `patina install` otherwise puts
it on the command line only through GRUB's configuration. Then Path A, as in
`docs/vm-run.md`. Same rule as the Raspberry Pi 4: a clean Debian per attempt,
correctness over UX.

## Known caveats to expect

- Suspend works but drains the battery within a day.
- Shutdown with the charger connected rebooted instead on the T14s Gen 6 until firmware
  2.29; update the UEFI firmware first.
- With an encrypted root, `deferred_probe_timeout=30` gives the passphrase 30 seconds;
  typed later, some devices fail to start (#1151632).
- Debian bugs worth reading before a run: #1134104 (USB on the T14s's right side, fixed
  from kernel 7.0, so in the backports kernel), #1138699 (systemd-boot and the kernel's
  64 KiB alignment), #1139313 (random crashes).
- Secure Boot is not covered by the wiki; whether Debian's signed shim and GRUB can load
  the device tree on these machines is an open question for the run.
