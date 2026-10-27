# Snapdragon X Elite laptops

The first ARM laptops on the roadmap (Phase 4). Debian runs on them with caveats, from
Debian's own kernel and firmware packages, so the entry exists; nobody has run patina
on one yet, so the status is untested. `device.yaml` holds the facts, `docs/hardware.md`
records results. The reference is Debian's own page for the ThinkPad T14s Gen 6:
<https://wiki.debian.org/InstallingDebianOn/Thinkpad/T14s_Gen6_Snapdragon>.

## What is different from a PC

- No usable ACPI tables and no device-tree partition: the boot loader must load the
  model's device tree (`models` in `device.yaml`) from the ESP and pass it to the
  kernel. Debian's installer and the patina live image do not do that, so Path B is
  not an option and Path A starts from a manual install.
- Debian 13's release kernel (6.12) is older than the laptop support upstream. The Debian
  wiki installs the kernel and firmware from `trixie-backports` (7.2 at the time of
  writing); the device trees come with that kernel under
  `/usr/lib/linux-image-<version>-arm64/qcom/`.
- Firmware for the SoC is per model. Debian 13's `firmware-qcom-soc` carries the
  ThinkPad T14s Gen 6 and the Yoga Slim 7x; for the other models the blobs live on the
  Windows partition. The devices rules allow a helper that copies them from the user's
  own machine, but it is written only after a run shows exactly which files are missing.
- Everything that works upstream works from Debian's archive. Bluetooth and the camera
  need an out-of-tree kernel branch, which patina will never ship (no own kernel, no
  out-of-tree modules): they wait for upstream.

## The run

Same rule as the Raspberry Pi 4: a clean install per attempt, correctness over UX.

1. Install Debian 13 following the Debian wiki page: debootstrap, systemd-boot with a
   `devicetree` line in the boot entry, kernel and firmware from `trixie-backports`,
   plus `firmware-qcom-soc` and `firmware-atheros`. Note the kernel command line the
   wiki settles on; it goes into `kernel_params` in `device.yaml`, as data.
2. Install the desktop Path A assumes, from Debian's archive, and create the user:

   ```sh
   apt install kde-plasma-desktop sddm kwin-wayland plasma-nm plasma-pa pipewire-audio \
     kscreen powerdevil xdg-desktop-portal-kde
   adduser <name> && adduser <name> sudo
   systemctl reboot
   ```

3. Path A, as that user:

   ```sh
   git clone https://github.com/patina-os/patina ~/.local/share/patina
   mkdir -p ~/.local/bin && ln -s ~/.local/share/patina/bin/patina ~/.local/bin/patina
   patina install
   ```

4. Run `patina install` a second time: it must change nothing.
5. Record the result as a row in `docs/hardware.md` (model, firmware version, kernel
   version, what failed). Keep the speaker volume low until upstream has speaker
   protection; the wiki is explicit about that.

## Known caveats to expect

- Suspend works but drains the battery within a day.
- Shutdown with the charger connected rebooted instead on the T14s Gen 6 until firmware
  2.29; update the UEFI firmware first.
- Debian bugs worth reading before a run: #1134104 (USB on the T14s), #1138699
  (systemd-boot and the kernel's 64 KiB alignment), #1139313 (random crashes).
- Secure Boot is not covered by the wiki; whether Debian's signed shim and GRUB can load
  the device tree on these machines is an open question for the run.
