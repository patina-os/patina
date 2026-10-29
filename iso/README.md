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
  live/config/hooks/        one build hook: boot the live system into the installer
  live/config/includes.chroot/
    etc/calamares/settings.conf        the pages shown and the steps run
    etc/calamares/modules/*.conf       one file per step; packages.conf is the list the
                            installer fetches from Debian's mirrors (Plasma and the base
                            bundle) and the live tooling it removes afterwards;
                            packagechooser-ai.conf the AI page
    etc/calamares/branding/patina/   the strings; the marks, artwork, stylesheet and
                            colours next to them are rendered by assets.sh
    etc/systemd/system/patina-ui.service  the installer screen (X, openbox, Calamares)
    root/.xinitrc                      that session, with the Wi-Fi step before it
    root/.config/openbox/rc.xml        openbox with the patina theme for the dialogs
  live/templates/           what assets.sh fills from the theme's palette and the fonts:
                            calamares/ (stylesheet.qss, the wallpaper and the slides as
                            SVG compositions, ai.svg for the pictures of the AI page,
                            logo-square.svg for the sidebar's mark, icons/ in the
                            accent), grub/ (theme.txt, splash.svg), openbox/,
                            fontconfig/ (the live system's standard fonts), xterm/
                            (the Wi-Fi step's terminal)
  live/assets.sh            renders the above plus branding/ into a build directory: the
                            console mark, the installer's files, the boot menu's theme
                            and splash; no root, so the smoke test runs it too
  live/build.sh             assembles iso/build/live/ (gitignored) from the above plus
                            assets.sh's output and firstboot/, then runs lb
  firstboot/                the systemd unit and script that run Path A on first boot;
                            build.sh puts them into the image, Calamares enables the unit
  test/boot-test.sh         the automated release gate: the image boots to the installer;
                            it also takes the screenshot of the installer screen
  test/list-packages.sh     every package the manifest and the image name, for the apt
                            dry run in the smoke workflow
```

## How an install works

1. Boot the image. The GRUB menu shows the theme's wallpaper and the wordmark. The live
   system starts `patina-ui.service`: an X session on tty7 with Calamares full screen
   in the theme's palette and fonts and in British English (`locales=` in
   `auto/config`; the welcome page offers the others), the block-letter name on the
   welcome page, the square mark in the sidebar, the wallpaper veiled behind every
   page, the sidebar and the button bar as glass over it (the start menu's `glass` and
   `grain` from `defaults/settings.yaml`), four still slides while it
   installs, the last one thanking the people and projects of `docs/credits.yaml`. The console shows `branding/logo.txt`.
   A computer with no network yet but a Wi-Fi card first gets the Wi-Fi step:
   NetworkManager's `nmtui` full screen in the palette, to pick a network and type its
   password; Quit starts the installer. Leaving the installer brings the step back
   while the computer is still offline.
2. Calamares asks what it must: time zone and keyboard (pre-filled), disk (erase is
   preselected; encryption and manual partitioning are available), the user, and the AI
   agent (on this computer, from a cloud provider, or none, preselected from `ai.mode`
   of `defaults/settings.yaml`: none). The AI page installs nothing: its answer is
   handed to the first boot. The summary page is the last look before anything is
   written.
3. The live system is copied to disk (`unpackfs`), then Plasma and the base bundle are
   fetched from Debian's mirrors into it (`packages`, the list in
   `modules/packages.conf`), the live tooling and Calamares are removed from it, the
   first-boot unit is enabled (`shellprocess-firstboot.conf`), GRUB is installed with
   Debian's signed shim.
4. First boot: the service takes tty1 before the login screen, clones this repository
   into the user's `~/.local/share/patina`, links `~/.local/bin/patina` and runs
   `patina install`, which asks the remaining questions on tty1 (the theme and the app
   bundles, with `gum`, and for a cloud agent the provider and its login;
   `/etc/patina/firstboot.env` answers them: the installer writes the AI page's answer
   there as `PATINA_AI`, and more can be added by hand). Then it writes
   `/var/lib/patina/firstboot-done` and never runs again. A failed clone or install
   prints the Path A command to run by hand and still marks the boot done, so a machine
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
of `CHANGELOG.md`, a pre-release when the version has a pre-release part). An alpha tag
(`v0.1.0-alpha.1`) gets the release without images: the alphas are Path A only, and the
image is handed out once its manual install check has passed. The workflow also runs on
every pull request that touches `iso/`, `branding/`, the base bundle or the workflow
itself, so an image change is built and booted before it is merged; it publishes only
from a tag. To build by hand on a Debian machine of the target architecture:

```sh
sudo apt-get install live-build debootstrap librsvg2-bin fonts-adobe-sourcesans3 \
  fonts-jetbrains-mono fonts-sora
sudo iso/live/build.sh amd64            # writes iso/build/live/patina-amd64.hybrid.iso
sudo iso/live/build.sh arm64            # on an arm64 machine
```

`build.sh` calls `assets.sh`, which renders everything the image shows from the data:
`branding/logo.txt` into `/etc/issue.d`, `branding/wordmark.svg` (as a PNG) and
`icon-small.svg` (inset in the sidebar's box) into the installer's branding, the icons
of `live/templates/calamares/icons/` in the accent, the default theme's wallpapers under a veil as the installer's
background, four slides (the last one the names of `docs/credits.yaml`), the splash of the boot menu, and the templates under
`live/templates/` (the Calamares stylesheet, the GRUB theme, the openbox theme) with the
palette of `themes/<default>/theme.yaml` and the fonts of `defaults/settings.yaml`,
plus the version and the sidebar colours into `branding.desc` with `yq`, and
`/etc/fonts/local.conf`, which makes the layer's fonts the live system's standard ones:
Calamares draws its sidebar in Qt's application font, which the stylesheet does not
reach. Nothing
generated is committed, no colour is typed by hand, and the marks keep their single
copies. To see the output without a build: copy `iso/live/config` somewhere and run
`iso/live/assets.sh <that directory>`; the smoke workflow does the same and checks the
files.

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
  install page with the gradient progress bar and the four slides; at first boot the
  mark on tty1 and the questions; then the login screen with the theme's wallpaper,
  the splash with the wordmark and the accent line, and the desktop in Source Sans 3
  and JetBrains Mono, as `docs/screenshots/desktop-amd64.png` shows it.
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

- The look on a screen, listed under the release gate above: Calamares scales
  `logo-square.png` to 80x80 and `welcome.png` (the block-letter name of
  `branding/export/` rendered with `rsvg-convert`) on the welcome page; `productWallpaper`
  tiles on screens larger than 1920x1080 (if it looks wrong, the veiled wallpaper goes
  and `#mainApp`'s background stays); the stylesheet over Fusion on Calamares' own
  widgets (the partition bars keep Calamares' colours by design); GRUB's `crop` scaling
  of the splash at live-build's 800x600 mode. Written against Calamares 3.3.14's source
  and still to be seen on a screen: the sidebar's steps (`qproperty-spacing`, margin
  and padding on `#sidebarMenuApp`, the `#AARRGGBB` style colours), the glass of the
  sidebar and of the unnamed button bar (`#backgroundWidget > QWidget`), the blurred
  strip assuming the sidebar's 190 px, and the accent icons of the welcome page's
  links and About (`qproperty-icon`, applied when Qt polishes the buttons).

- `grub-install` picks the signed images only when `grub-efi-<arch>-signed` and
  `shim-signed` are present in the target; they come from the live system
  (`live/arch/<arch>.list.chroot`) and must survive the `remove` list. The manual
  install on a Secure Boot machine is the check.
- The AI page: Calamares 3.3.14's `packagechooser` with the `legacy` method, its
  pictures found in the branding directory, and `${gs[packagechooser_ai]}` filled in
  `shellprocess-firstboot.conf`, as the module documentation of that release describes
  them; the manual install is the check (`/etc/patina/firstboot.env` names the answer).
- The arm64 image on real hardware: the boot test covers the QEMU `virt` machine only.
