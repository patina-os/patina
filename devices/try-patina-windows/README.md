# Try patina for Windows

patina in a QEMU virtual machine on a Windows 10 or 11 PC (x86_64), set up and started by
TryPatina.exe from [patina-os/win-emulator](https://github.com/patina-os/win-emulator).
The launcher installs stock QEMU with winget, downloads the released
`patina-amd64.hybrid.iso`, checks it against the release's `SHA256SUMS`, and boots it
next to an empty virtual disk. The installer puts patina on that disk as on a PC, and
first boot runs `patina install` as always.

## What this directory adds

The launcher gives the machine the product name `Try patina` (`-smbios
type=1,product=Try patina`), which `patina install` reads from
`/sys/class/dmi/id/product_name`. On that machine, and only there, it also:

- installs `spice-vdagent`, which shares the clipboard with QEMU's GTK window through
  QEMU's built-in vdagent (no SPICE client is needed on Windows). The window has the
  Windows clipboard from QEMU 11.1 on, when the launcher asks for it (`-display
  gtk,clipboard=on`); the Windows builds of QEMU before 11.1 have none;
- installs `kwin-x11` and writes `system/sddm.conf.d/try-patina.conf`, so the login
  screen offers the Plasma X11 session first and logging in automatically (the
  installer's checkbox, or System Settings, Login Screen) starts it: spice-vdagent
  shares the clipboard only in an X11 session (its Wayland support is not released).
  Plasma (Wayland) stays on the session menu of the login screen. The file comes after
  `kde_settings.conf`, where the installer and Plasma's settings put the automatic
  login, so its sessions win.

## Known caveats

- Software rendering: stock QEMU gives the guest no GPU, so animations are slower than
  on hardware.
- The CPU model is a safe subset (`qemu64` with SSSE3, SSE4 and AES); stock QEMU on the
  Windows Hypervisor Platform does not pass AVX through.
- The disk is an NVMe disk, not virtio, so the I/O scheduler rules of
  `defaults/system/udev/` apply as on a laptop.
- Installed from 0.1.0-alpha.4 or older with automatic login: that installer wrote the
  automatic login's session (`plasma`, Wayland) to `/etc/sddm.conf`, which SDDM reads
  after `/etc/sddm.conf.d/`. Pick Plasma (X11) for it in System Settings, Login Screen
  (SDDM), Behavior: saving moves the setting into `kde_settings.conf`.

## Validation

1. On a Windows PC with the Windows Hypervisor Platform turned on, run TryPatina.exe and
   install patina in the window that opens.
2. After the first login: `cat /sys/class/dmi/id/product_name` prints `Try patina`,
   `patina doctor` names the device and is clean, `echo $XDG_SESSION_TYPE` prints `x11`,
   with the installer's automatic login as well.
3. Copy text in Windows and paste it in kitty, then the other way round.
4. Record the run in `docs/hardware.md`.
