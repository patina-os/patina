# Try patina for Windows

patina in a QEMU virtual machine on a Windows 10 or 11 PC (x86_64), set up and started by
TryPatina.exe from [patina-os/win-emulator](https://github.com/patina-os/win-emulator).
The launcher installs stock QEMU with winget, asks in a setup window what patina's
installer asks on a PC, downloads the released `patina-amd64.qcow2`, checks it against
the release's `SHA256SUMS`, and starts it under a layer that keeps the machine's
changes. The disk is the system the installer leaves (`iso/disk/`), without an account;
its first boot sets the account up from the setup's answers, then runs `patina install`
as always. The launcher can also install from `patina-amd64.hybrid.iso` with the
installer, as on a PC: from its menu, or by itself for a release without the disk.

## The setup's answers

TryPatina.exe hands the answers to the guest once, as QEMU firmware configuration
(`-fw_cfg name=opt/io.github.patina_os/setup,file=…`), a file of one `KEY=value` per line:

| Key | Value | The installer's page |
|---|---|---|
| `PATINA_USER` | the login name: small letters, digits, `-` and `_` | Users |
| `PATINA_FULLNAME` | the user's name | Users |
| `PATINA_PASSWORD` | the password, also sudo's | Users |
| `PATINA_HOSTNAME` | optional; `<user>-patina` without it | Users |
| `PATINA_LOCALE` | a glibc locale such as `de_DE.UTF-8`, Windows' by default | Location |
| `PATINA_KEYBOARD_LAYOUT`, `PATINA_KEYBOARD_VARIANT` | XKB, such as `de` and `nodeadkeys`, Windows' by default | Keyboard |
| `PATINA_TIMEZONE` | an IANA zone such as `Europe/Berlin`, Windows' by default | Location |
| `PATINA_AI_AGENT`, `PATINA_AI`, `PATINA_BUNDLES`, `PATINA_THEME` | as the installer writes them to `/etc/patina/firstboot.env` | AI agent, AI model, Apps and More apps, Theme |

The window shows the installer's own pages, which the image build publishes as
`patina-setup.json` (`iso/disk/choices.sh`): their words in English and German, their
pictures and defaults, the default theme's palette and the fonts. `firstboot/` holds the
step that reads the answers (`patina-vm-setup.sh` and its unit), run once before patina's
first boot and the login screen. It checks every value against what Debian has and keeps
the image's own (British English, a US keyboard, UTC) where one does not fit, and reports
on the machine's first serial port, which the launcher keeps as `serial.log` in its data
folder and reads to delete the answers once the guest says `patina vm setup: done`.

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
  login, so its sessions win;
- writes `system/default/grub.d/try-patina.cfg`, which starts GRUB at 1920x1080, the
  display's one resolution: the firmware reports no preferred mode, so GRUB kept
  800x600, and the boot menu stood in a 4:3 box in the window.

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

1. On a Windows PC with the Windows Hypervisor Platform turned on, run TryPatina.exe,
   answer its setup window and wait for patina's first boot to end at the login screen.
   Once, use "Install with patina's installer…" from its menu and install patina in the
   window that opens.
2. After the first login: `cat /sys/class/dmi/id/product_name` prints `Try patina`,
   `patina doctor` names the device and is clean, `echo $XDG_SESSION_TYPE` prints `x11`,
   with the installer's automatic login as well.
3. Copy text in Windows and paste it in kitty, then the other way round.
4. Record the run in `docs/hardware.md`.
