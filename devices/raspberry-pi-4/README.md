# Raspberry Pi 4

The first aarch64 target. Nothing here is specific to patina beyond the fact list in
`device.yaml`: Debian's official Raspberry Pi image carries the firmware, kernel and
device tree, and the layer has no architecture. This page is the manual validation
procedure from the roadmap's Phase 4; `docs/hardware.md` records the result.

## What you need

- A Raspberry Pi 4 Model B with 4 GiB or 8 GiB of RAM (2 GiB runs, but Plasma swaps).
- A USB SSD (an SD card works for the run, but is slow enough to confuse timing
  problems with real ones). The Pi 4 boots from USB with a bootloader EEPROM from 2020
  or later; `rpi-eeprom-update` on Raspberry Pi OS or `vcgencmd bootloader_version`
  tells.
- Wired network, so the run does not depend on wifi firmware.
- Debian's official Raspberry Pi image for the Pi 4 and Debian 13 from
  <https://raspi.debian.net/tested-images/> (the `raspi_4` family). It is console only.

## The run

Every run starts from a clean reimage, so a result is reproducible and never depends on
leftovers from the previous attempt.

1. Write the image: `xzcat <image>.img.xz | sudo dd of=/dev/sdX bs=4M status=progress`
   and `sync`. Set a root password in `sysconf.txt` on the first partition
   (`root_pw=...`), or leave the console login open as the image's README describes.
2. Boot, log in on the console, let the first-boot resize finish, then update:
   `apt update && apt full-upgrade`.
3. Install the desktop Path A assumes, from Debian's archive (the same list the image's
   `modules/packages.conf` installs), create a regular user in the `sudo` group and
   reboot into SDDM:

   ```sh
   apt install kde-plasma-desktop sddm kwin-wayland plasma-nm plasma-pa pipewire-audio \
     kscreen powerdevil xdg-desktop-portal-kde
   adduser <name> && adduser <name> sudo
   systemctl reboot
   ```

4. Path A, as that user:

   ```sh
   git clone https://github.com/patina21/patina ~/.local/share/patina
   mkdir -p ~/.local/bin && ln -s ~/.local/share/patina/bin/patina ~/.local/bin/patina
   patina install
   ```

5. Run `patina install` a second time: it must change nothing.
6. Record the result as a row in `docs/hardware.md` (status, date, image version, what
   failed), and open an issue for anything that is not a bug in the layer itself. If the run needs a
   kernel parameter or an extra package, it goes into `device.yaml`, not into a script.

The goal is correctness, not UX: a Pi 4 that ends in the same desktop as the x86_64 VM
is a pass, however long it took.

## The generic arm64 live image

The patina arm64 image targets machines that boot a generic UEFI Debian; the Pi 4
does not, out of the box. The community UEFI firmware from <https://github.com/pftf/RPi4>
makes it one, but it is a third-party binary that patina neither ships nor tests.
If you use it, the image's boot test (QEMU `virt` machine) is the closest thing to a
reference, and a successful install is worth a row in `docs/hardware.md` too.
