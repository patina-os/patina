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

Same rule as the Raspberry Pi 4: a clean Debian per attempt, correctness over UX. The
steps keep Windows beside Debian; on a laptop without it, skip step 1 and give Debian
the whole disk.

1. In Windows, before anything else:
   - Update the UEFI firmware to N42ET99W (2.29) or later, with Lenovo's updater from
     its support site. Older versions rebooted instead of shutting down on the charger.
   - Write down the BitLocker recovery key (`manage-bde -protectors -get C:` in an
     administrator's terminal, or your Microsoft account's devices page): Windows asks
     for it at its next start once Secure Boot changes.
   - Turn off Fast Startup (Power Options), so Windows leaves its partition closed.
   - Shrink C: in Disk Management by at least 50 GB and leave the space unallocated.
   - In the UEFI setup (F1 at power-on), turn Secure Boot off for this run: whether
     Debian's signed boot chain can carry the device tree is still open.
2. Install Debian 13 into the free space, following the Debian wiki page: debootstrap,
   kernel and firmware from `trixie-backports`, plus `firmware-qcom-soc` and
   `firmware-atheros`, and systemd-boot. The wiki does not say which system runs
   debootstrap; any arm64 Linux the laptop boots from a USB stick will do, and the
   record says which one did. For the boot:
   - Windows' EFI partition is often 260 MB, too small for Debian's kernels beside
     Windows' files. Make a 1 GiB FAT32 partition of type XBOOTLDR
     (`bc13c2ff-59e6-4262-a352-b275fd779ff1`) in the free space and mount it at `/boot`,
     the root partition after it; Windows' EFI partition goes to `/efi`, where
     `bootctl install` puts systemd-boot, which lists Windows by itself.
   - Before the kernel is installed, write the model's device tree to
     `/etc/kernel/devicetree` (`qcom/x1e78100-lenovo-thinkpad-t14s.dtb` or the
     `-oled` one) and the whole command line to `/etc/kernel/cmdline`:

     ```text
     root=UUID=<the root partition's UUID> rw clk_ignore_unused deferred_probe_timeout=30 quiet splash
     ```

     systemd's kernel-install then copies the device tree beside each kernel and writes
     it into the kernel's boot entry, updates included. `quiet splash` is for patina's
     boot splash, which `patina install` otherwise puts on the command line only
     through GRUB's configuration.
3. Install the desktop Path A assumes, from Debian's archive, and create the user:

   ```sh
   apt install kde-plasma-desktop sddm kwin-wayland plasma-nm plasma-pa pipewire-audio \
     kscreen powerdevil xdg-desktop-portal-kde
   adduser <name> && adduser <name> sudo
   systemctl reboot
   ```

4. Path A, as that user:

   ```sh
   git clone https://github.com/patina-os/patina ~/.local/share/patina
   mkdir -p ~/.local/bin && ln -s ~/.local/share/patina/bin/patina ~/.local/bin/patina
   patina install
   ```

5. Run `patina install` a second time: it must change nothing.
6. Record the result as a row in `docs/hardware.md`: model and screen, UEFI firmware
   version (`sudo dmidecode -s bios-version`), kernel version, the Linux that ran
   debootstrap, what failed, and the output of
   `cat /sys/class/dmi/id/{sys_vendor,product_name,product_version,product_family}`,
   from which a `detect` map can be written. Keep the speaker volume low until upstream
   has speaker protection; the wiki is explicit about that.

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
