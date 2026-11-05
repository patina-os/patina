# iso/

The patina live image: Debian's live-build and the Calamares installer, driven by our
data. The image contains no logic of its own; it automates the stock-Debian path
(Path A) and nothing else. If Path A and the image ever diverge, Path A wins and the
image is fixed.

Status: builds and boots (roadmap, Phases 2 and 3). The amd64 image builds with
live-build 20250505 and Calamares 3.3.14 as Debian 13 ships them and reaches the
installer screen in QEMU; the `iso` workflow repeats that on every change and builds and
boots the arm64 image the same way. What each file assumes is written next to it, and
what the first build settled, plus what is still open, is at the end of this page.

```text
iso/
  live/auto/config          live-build options (`lb config` reads it): Debian 13, UEFI
                            with Secure Boot, main plus non-free-firmware, no installer
                            of Debian's own
  live/config/package-lists/  the live system: live-boot, NetworkManager, firmware,
                            Calamares and a bare X session for it. No Plasma here
  live/config/apt/preferences  build-time pins that keep two large Recommends out of
                            the live system; not part of the image
  live/arch/<arch>.list.chroot  the few per-architecture packages (signed GRUB and shim,
                            microcode); build.sh copies the right one in
  live/config/hooks/        two build hooks: boot the live system into the installer,
                            and name the boot menu's entries Install patina
  live/config/includes.chroot/
    etc/calamares/settings.conf        the pages shown and the steps run
    etc/calamares/modules/*.conf       one file per step; packages.conf is the list the
                            installer fetches from Debian's mirrors (Plasma and the base
                            bundle) and the live tooling it removes afterwards;
                            packagechooser-agent.conf, -ai.conf, -apps.conf,
                            -more.conf and -theme.conf the agent, AI, apps, more-apps
                            and theme pages
    etc/calamares/branding/patina/   the strings; the marks, artwork, stylesheet and
                            colours next to them are rendered by assets.sh
    etc/systemd/system/patina-ui.service  the installer screen (X, openbox, Calamares)
    root/.xinitrc                      that session, with the Wi-Fi step before it
    root/wifi-step.sh                  the Wi-Fi step: nmtui until the computer is online
    root/.config/openbox/rc.xml        openbox with the patina theme for the dialogs, and the brightness keys
  live/templates/           what assets.sh fills from the theme's palette and the fonts:
                            calamares/ (stylesheet.qss, the wallpaper and the slides as
                            SVG compositions on slide-ground.svg, ai.svg, bundle.svg
                            and theme.svg for the pictures of the four question pages,
                            logo-square.svg for the sidebar's mark, icons/ in the
                            accent), openbox/,
                            fontconfig/ (the live system's standard fonts), xterm/
                            (the Wi-Fi step's terminal)
  live/assets.sh            renders the above plus branding/ into a build directory: the
                            console mark, the installer's files, the boot menu's theme
                            (defaults/boot/grub/, with live-build's theme.cfg in
                            config/bootloaders/grub-pc/, which loads its font), the
                            boot splash, and an installed system's boot menu with its
                            GRUB setting; no root, so the smoke test runs it too
  live/build.sh             assembles iso/build/live/ (gitignored) from the above plus
                            assets.sh's output and firstboot/, then runs lb
  firstboot/                the systemd unit and script that run Path A on first boot;
                            build.sh puts them into the image, Calamares enables the unit
  disk/build.sh             Try patina's disk image (below): the installer's system,
                            without an account, as a compressed qcow2
  disk/choices.sh           the installer's pages as patina-setup.json, for Try patina's
                            setup window, from a live build directory
  test/boot-test.sh         the automated release gate: the image boots to the installer;
                            it also takes the screenshot of the installer screen
  test/disk-test.sh         the same for the disk image: its first boot sets an account up
                            from answers as Try patina hands them over
  test/second-boot-test.sh  the disk image started twice, with patina's system files and
                            boot splash in place: the login screen follows the splash
  test/list-packages.sh     every package the manifest and the image name, for the apt
                            dry run in the smoke workflow
```

## How an install works

1. Boot the image. The GRUB menu shows the theme's wallpaper with the block-letter name
   centred above a centred menu column: Install patina, Install patina (fail-safe
   mode, live-build's options for awkward firmware) and Utilities (the firmware's
   settings, a check of the boot medium). While the live system boots, the boot splash
   builds the mark from `branding/logo.txt` (Plymouth, `defaults/boot/`, drawn into the
   image by `assets.sh`). Then `patina-ui.service` takes over the splash's last picture:
   an X session on tty7 with Calamares full screen
   in the theme's palette and fonts and in British English (`locales=` in
   `auto/config`; the welcome page offers the others), the block-letter name on the
   welcome page, the square mark in the sidebar, the wallpaper veiled and frosted behind
   every page, the sidebar and the button bar as glass over it (the start menu's `glass` and
   `grain` from `defaults/settings.yaml`), and while it installs a tour of patina in seven
   still slides, in the landing page's dark style (patina-os/landing): welcome, the
   desktop and the command palette with the desktop workflow's screenshots, the apps,
   the promises, the thanks to the people and projects of `docs/credits.yaml`, and what
   happens after the restart (the stick out, the first start, the password), which
   Calamares' own last page does not say.
   The session scales to the screen's physical size, as Windows does (150 % on a
   13.3" Full HD laptop, 100 % on a 24" monitor or in a virtual machine), never below
   1280x720 of room for the pages: `.xinitrc` sets X's `Xft.dpi`, which Qt 6 and
   xterm follow. The brightness keys work there (openbox runs brightnessctl, which
   the installer removes from the installed system), and a screen below 70 % starts
   at 70 %.
   Calamares shows a still slide for two seconds, so `branding.desc` lists each one
   five times. The console shows `branding/logo.txt`.
   A computer with no network yet but a Wi-Fi card first gets the Wi-Fi step:
   NetworkManager's `nmtui` full screen in the palette, to pick a network and type its
   password; once the computer is online the installer starts by itself. A network
   that did not connect is forgotten, so picking it again asks for its password
   again. Quit while still offline asks Try again or Start installer (to go on
   without a network). Leaving the installer brings the step back while the
   computer is still offline.
2. Calamares asks what it must: time zone and keyboard (pre-filled), disk (erase is
   preselected; encryption and manual partitioning are available), the user, the AI
   agent (on this computer, from a cloud provider, or none, preselected from `ai.mode`
   of `defaults/settings.yaml`: none), the apps (Standard, the bundle marked default,
   or Minimal), more apps (any of the other optional bundles: headstart, ArtCraft, the
   agent tools; more than one with Ctrl held, as the page says) and the theme (every theme of `themes/`, the default preselected, each
   pictured in its own palette). These pages install nothing: their answers are handed
   to the first boot. The summary page is the last look before anything is written; it
   lists the location, the keyboard and the disk, but not the user or these five
   pages, which Calamares' widget pages do not report to it.
3. The live system is copied to disk (`unpackfs`), then Plasma and the base bundle are
   fetched from Debian's mirrors into it (`packages`, the list in
   `modules/packages.conf`, in five installs, smallest first, so the progress bar moves;
   apt shows nothing while each runs), the live tooling and Calamares are removed from
   it, SDDM is set up and the hardware clock set (after the packages that bring them; the
   automatic login, when the user page asks for it, goes to
   `/etc/sddm.conf.d/kde_settings.conf`, where Plasma's Login Screen settings keep it, so
   a device's own SDDM file can still choose the session), the
   first-boot unit is enabled and what the image added for the installer alone (its
   configuration and branding, the installer screen, the console's mark) and apt's
   download cache are removed (`shellprocess-firstboot.conf`), GRUB is installed with
   Debian's signed shim into `EFI/debian`, where Debian's packages update it, and shim
   also at the removable path (`shellprocess-efi-removable.conf`), so the machine boots
   when the firmware loses its boot entries.
4. First boot: the boot splash shows (the installer copied it and Plymouth with the live
   system, and Calamares put `splash` on the kernel's line because Plymouth is there),
   and the service quits it and takes tty1 before the login screen, clones this repository
   into the user's `~/.local/share/patina`, links `~/.local/bin/patina` and runs
   `patina install` with the installer's answers from `/etc/patina/firstboot.env`
   (`PATINA_AI`, `PATINA_BUNDLES` as `--bundles`, `PATINA_THEME`), so it asks nothing
   on tty1 but the user's password for sudo, as Path A's install does (the password
   given to the installer), and a cloud agent's provider and opencode's own key login.
   The mark is printed first, since the install itself asks no question that would
   print it. An image older
   than the apps and theme pages writes `PATINA_AI` alone, and the install asks the
   theme and the bundles there. What the install prints is kept in
   `/var/log/patina-firstboot.log` (root's, through `script`, as `docs/vm-run.md` keeps
   Path A's), its steps in the journal. Then it writes
   `/var/lib/patina/firstboot-done` and never runs again. The clone gets three tries a
   little apart, for a network that comes up late, into a directory of its own that
   takes the checkout's place only when complete, so a machine turned off in the middle
   leaves no half checkout behind. A failed clone or install says what to run by hand
   and holds that on tty1 until Enter (or five minutes), before the login screen covers
   it, and leaves the first boot armed: the next start tries again, three starts in all
   (`/var/lib/patina/firstboot-tries`), after which it marks the boot done, so a machine
   never loops on first boot.

That is Path A, executed for the user. The image carries only the installer, its
configuration, the network stack and firmware, so it stays under a gigabyte (873 MB
for amd64) and Debian's mirrors carry the download, not us. The installed system is current Debian
stable at install time, and an old image installs today's layer.

## Building

`.github/workflows/iso-build.yml` does it for both architectures: `iso/live/build.sh
<arch>` in a privileged Debian 13 container on an x86_64 and on an aarch64 runner (a
native build on each, no emulation), then the boot test on a plain runner of the same
architecture, then, for a `v*` tag, the upload of both images and their `SHA256SUMS` to
that tag's GitHub release (created as a draft when missing, its notes the tag's section
of `CHANGELOG.md`, a pre-release when the version has a pre-release part; a release made
by hand on GitHub stays as it is and gets those notes only when it has none). An alpha tag
(`v0.1.0-alpha.3`) gets the amd64 image only: it passed its manual install check, the
arm64 image has not yet and stays in CI until it does. The release stays a draft until
the manual install check below has passed on the uploaded image. The workflow also runs on
every pull request that touches `iso/`, `branding/`, the base bundle or the workflow
itself, so an image change is built and booted before it is merged; it publishes only
from a tag.

A release needs no tag pushed by hand: once `CHANGELOG.md` has the version's section,
the `release` workflow (Actions, release, Run workflow on `main`, with the version as
the changelog names it, `0.1.0-alpha.8`) checks that the version is new, that the section
is there and that lint and smoke passed on the commit, tags it `v<version>` and starts
this workflow on the tag; its own token may dispatch a workflow but not start one by a
tag push. A `v*` tag pushed by hand starts it as before. Either way the release is a
draft until the manual install check has passed.

To build by hand on a Debian machine of the target architecture:

```sh
sudo apt-get install live-build debootstrap librsvg2-bin fonts-adobe-sourcesans3 \
  fonts-jetbrains-mono fonts-sora
sudo iso/live/build.sh amd64            # writes iso/build/live/patina-amd64.hybrid.iso
sudo iso/live/build.sh arm64            # on an arm64 machine
```

`build.sh` calls `assets.sh`, which renders everything the image shows from the data:
`branding/logo.txt` into `/etc/issue.d`, the block-letter name of `branding/export/` (as a
PNG, for the welcome page, the slides and the boot menu) and `icon-small.svg` (inset in
the sidebar's box) into the installer's branding, the icons
of `live/templates/calamares/icons/` in the accent, the default theme's wallpapers under a veil as the installer's
background, seven slides on one ground (`slide-ground.svg`) with `docs/screenshots/` of the
desktop and the command palette (the sixth slide the names of `docs/credits.yaml`), the
boot menus of `defaults/boot/grub/` (the live image's at 800x600, and an installed
system's with `defaults/system/default/grub.d/patina.cfg`, which the installer copies to
the disk, so the first start after the install shows patina's menu), and the templates
under `live/templates/` (the Calamares stylesheet, the openbox theme) with the
palette of `themes/<default>/theme.yaml` and the fonts of `defaults/settings.yaml`,
plus the version and the sidebar colours into `branding.desc` with `yq`, and
`/etc/fonts/local.conf`, which makes the layer's fonts the live system's standard ones:
Calamares draws its sidebar in Qt's application font, which the stylesheet does not
reach. Nothing
generated is committed, no colour is typed by hand, and the marks keep their single
copies. To see the output without a build: copy `iso/live/config` somewhere and run
`iso/live/assets.sh <that directory>`; the smoke workflow does the same and checks the
files.

## Try patina's disk image

TryPatina.exe (`patina-os/win-emulator`) starts patina in a virtual machine on Windows.
Instead of running the installer in it, it boots `patina-amd64.qcow2`, which
`disk/build.sh` makes: the disk the installer leaves, built with debootstrap from the
same lists (the live system's without what the installer removes, the architecture's,
and what `modules/packages.conf` installs), the first boot armed, shim and GRUB where
the installer puts them (`EFI/debian` and the removable path), without an account, and
without firmware and microcode, which a virtual machine has no hardware for. The disk is
128 GiB, the launcher's ceiling, and costs only what is written; a compressed qcow2 of
it is what the launcher downloads and keeps, under a layer for the machine's changes.
What the installer's pages ask, the launcher asks on Windows (the account, the language,
keyboard and time zone, the apps, the AI agent and the theme) and hands to the guest,
whose first boot sets them up (`devices/try-patina-windows/`) before Path A runs as
always. The window shows the installer's own pages: `disk/choices.sh` writes them, as
`assets.sh` filled them in, with their pictures, the default theme's palette and the
fonts, to `patina-setup.json`, a release asset beside the image. GitHub takes no
release file of 2 GiB or more, so the disk is published in parts of 1900 MiB
(`patina-amd64.qcow2.001` and on); `SHA256SUMS` names each part and the whole, and the
launcher checks both as it joins them.

```sh
sudo iso/disk/build.sh amd64 iso/build/disk                     # half an hour or so
iso/test/disk-test.sh iso/build/disk/patina-amd64.qcow2         # its first boot
sudo iso/test/second-boot-test.sh iso/build/disk/patina-amd64.qcow2   # the next
iso/disk/choices.sh iso/build/live iso/build/patina-setup.json  # after live/build.sh
```

The build needs root and loop devices, nothing a privileged container lacks: it mounts
only the system's ext4 and writes the EFI system partition with mtools. GRUB cannot
install itself on a loop device, so the build copies Debian's signed shim and GRUB where
the installer's step puts them, with a configuration for the one kernel, and the disk's
first boot runs `grub-install` and `update-grub` on its real disk. The workflow runs
build and boot test on the runner itself, for KVM.

## The release gate

- Automated: `test/boot-test.sh <iso>` boots the image in QEMU with the serial console
  attached and waits for `patina installer: ready`, which `.xinitrc` prints once
  Calamares is running. It proves the image, the kernel, the initrd and the installer
  session; the workflow runs it before any upload. It uses KVM where the runner has it
  and falls back to emulation (TCG) where it does not, with a longer timeout; GitHub's
  arm64 runners have no KVM, so the arm64 test is the slow one. The kernel is loaded by
  QEMU directly, so the test does not cover GRUB and shim; the manual install does.
  The VM has an empty 32 GiB disk (a sparse file, no space used), so the welcome page's
  requirement checks pass as they would on a laptop.
  Once the installer is up, the test asks QEMU's monitor for a screenshot of the
  display (`screendump`, which works without a window) and leaves it next to the serial
  log as `installer-<arch>.png`; the workflow uploads both in the `boot-test-<arch>`
  artifact. A missing screenshot is reported, not a failure: the gate is the boot.
- Manual, once per release: one real install in a VM through the installer, then a first
  boot that ends in `patina firstboot: done`. Calamares has no unattended mode, so
  this part is not automated; the roadmap keeps it as a Phase 3 item, first passed on
  amd64 in October 2026 (which showed the target's DNS and the fetched package set
  enough for first boot). The look is
  part of this check, since the boot test skips GRUB and shows no screen: the boot menu
  in the palette over the splash, readable; the installer's welcome page (the square
  mark in the sidebar, the wordmark on the page, the wallpaper behind, Source Sans 3), the partition
  page with the manual partition editor's dialog (openbox's patina frame), the
  install page with the gradient progress bar (its percentage readable over the
  chunk) and the seven slides; at first boot the
  mark on tty1 and the questions; then the login screen with the theme's wallpaper,
  the splash with the wordmark and the accent line, and the desktop in Source Sans 3
  and JetBrains Mono, as `docs/screenshots/desktop-amd64.png` shows it.
- Automated, for Try patina's disk image: `test/disk-test.sh` boots it as the launcher
  does (UEFI, shim and GRUB from the disk, an NVMe disk over it, the product name
  `Try patina`) with an answered setup and waits for the account step to report on the
  serial port that it set up the account with the language, keyboard and time zone it
  was given. `test/second-boot-test.sh` then starts a copy of it twice with what
  `patina install` leaves for the next start: its system files from
  `defaults/system/` and the device's `system/` and the boot splash, written into the
  copy, and the first boot's Path A marked as done. The first start sets the account
  up, rebuilds the initramfs and GRUB's menu as the install's apply step does and
  powers off; the second has to show the splash (`quiet splash`) and then SDDM's
  greeter, which a test unit reports on the serial port. It is the start that hung in
  0.1.0-alpha.7, which the first boot alone never reaches. The workflow runs both after
  the build; the release takes the disk only then.
- A failing build or test is simply not published; Path A users are never affected.

## Screenshots

`docs/screenshots/` holds the screenshots the README shows: the installer screen is
the boot test's own screenshot, copied from the `boot-test-amd64` artifact of the `iso`
workflow run that built the release; the desktop, the start menu and the command
palette are the `desktop` workflow's, copied from its `desktop-amd64` artifact with
`-amd64` added to their names (Path A in a Debian 13 container, then
`desktops/plasma/screenshot.sh`: a Plasma X11 session on a virtual framebuffer with
the start menu open, kitty and the greeting, then KRunner on kortex's answer from a
scripted model). They are the one generated thing committed, refreshed for every
release, never edited.

## Rules

- Every package comes from Debian's archive. The image adds only the installer
  configuration, the installer screen and branding within Debian's trademark policy
  (`docs/branding.md`). Firmware from `non-free-firmware` is the only non-free content.
- Debian's signed kernel, shim and GRUB stay untouched so Secure Boot keeps working. No
  kernel patches, no out-of-tree modules.
- The first-boot contract for `patina install` (Phases 1 and 2): honour `PATINA_UNATTENDED=1`
  (no prompts, defaults for everything), `PATINA_THEME=<name>` and
  `PATINA_AI=local|cloud|none` (with `PATINA_AI_PROVIDER=<id>`), and exit non-zero on
  failure so the first-boot script can say so.

## Settled by the first build

- `lb config` on Debian 13 accepts every option in `auto/config` as spelled, including
  `--uefi-secure-boot enable` and `--bootloaders grub-efi`.
- Calamares 3.3.14: the module keys match upstream's example configurations of that
  release. The branding `style` keys are capitalised (`SidebarBackground`), which the
  first build caught. Encryption is LUKS1: Calamares puts `/boot` inside the encrypted
  volume and Debian's GRUB cannot unlock LUKS2 with argon2id (`modules/partition.conf`).
- Calamares runs as root inside `dbus-run-session` on a bare X session without a polkit
  agent; the installer screen comes up and `.xinitrc` reports it.
- live-build names the kernel and initrd on the image `live/vmlinuz-<version>` and
  `live/initrd.img-<version>`; the boot test finds them by pattern.
- agetty treats backslashes in `/etc/issue` as escape sequences; `build.sh` doubles them
  in the console copy of the logo.
- live-build's own firmware detection (`--firmware-chroot`, on by default) and the
  `firmware-linux` metapackage each pull Debian's whole non-free firmware set, over 700
  MiB of it for network cards no laptop has, and made the first image 1.2 GB. With the
  detection off, the wifi and graphics families listed by hand and two large Recommends
  pinned out at build time (`config/apt/preferences`), the amd64 image is 873 MB; the
  installed system gets the full firmware set from `modules/packages.conf`.

## Still to verify

- The look on a real screen. Seen in QEMU at 1280x800 in November 2026, through a
  whole install: the boot menu over its splash at 800x600, the welcome page with the
  square mark and the block-letter name, the wallpaper veiled behind every page, the
  sidebar's steps and the glass of the sidebar and the button bar, the accent icons,
  the five question pages and their pictures, the six slides, and the finished page.
  That run found the partition legend black on black (Calamares draws its names in
  black whatever the style says; it has a light card now) and the steps outgrowing the
  sidebar (no spacing now). Still to see: `productWallpaper` on screens larger than
  1920x1080 (if it tiles, the veiled wallpaper goes and `#mainApp`'s background
  stays), and a laptop's own screen and scaling.

- `grub-install` picks the signed images only when `grub-efi-<arch>-signed` and
  `shim-signed` are present in the target; they come from the live system
  (`live/arch/<arch>.list.chroot`) with `grub-efi-<arch>` and must survive the `remove`
  list. On amd64 in QEMU with Secure Boot and Microsoft's keys (October 2026): the
  boot entry is `\EFI\debian\shimx64.efi`, a reinstall of `shim-signed` and the GRUB
  packages rewrites `EFI/debian` and `EFI/BOOT`, and with the boot entry deleted the
  machine boots from `EFI/BOOT/BOOTX64.EFI`. A real Secure Boot machine is still the check.
- The four question pages: Calamares 3.3.14's `packagechooser` with the `legacy`
  method, its pictures found in the branding directory, the more-apps page in
  `optionalmultiple` mode (its answer a comma-separated list, empty when nothing is
  picked: `Config::updateGlobalStorage` inserts the joined list either way, so
  `${gs[packagechooser_more]}` is always defined), and the answers filled in
  `shellprocess-firstboot.conf`, as the module's source in that release has it; the
  manual install is the check (`/etc/patina/firstboot.env` names the answers).
- The arm64 image on real hardware: the boot test covers the QEMU `virt` machine only.
