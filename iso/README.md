# iso/

The patina21 live image: Debian's live-build and the Calamares installer, driven by our
data. The image contains no logic of its own; it automates the stock-Debian path
(Path A) and nothing else. If Path A and the image ever diverge, Path A wins and the
image is fixed.

Status: scaffolded (roadmap, Phase 2). Nothing here has been built or booted yet; the
first run of the `iso` workflow is the step that verifies it. What each file assumes is
written next to it, and the list of things to verify is at the end of this page.

```text
iso/
  live/auto/config          live-build options (`lb config` reads it): Debian 13, UEFI
                            with Secure Boot, main plus non-free-firmware, no installer
                            of Debian's own
  live/config/package-lists/  the live system: live-boot, NetworkManager, firmware,
                            Calamares and a bare X session for it. No Plasma here
  live/arch/<arch>.list.chroot  the few per-architecture packages (signed GRUB and shim,
                            microcode); build.sh copies the right one in
  live/config/hooks/        one build hook: boot the live system into the installer
  live/config/includes.chroot/
    etc/calamares/settings.conf        the pages shown and the steps run
    etc/calamares/modules/*.conf       one file per step; packages.conf is the list the
                            installer fetches from Debian's mirrors (Plasma and the base
                            bundle) and the live tooling it removes afterwards
    etc/calamares/branding/patina21/   strings and colours; logo.svg is generated
    etc/systemd/system/patina21-ui.service  the installer screen (X, openbox, Calamares)
    root/.xinitrc                      that session
  live/build.sh             assembles iso/build/live/ (gitignored) from the above plus
                            branding/logo.txt and firstboot/, then runs lb
  firstboot/                the systemd unit and script that run Path A on first boot;
                            build.sh puts them into the image, Calamares enables the unit
  test/boot-test.sh         the automated release gate: the image boots to the installer
  test/list-packages.sh     every package the manifest and the image name, for the apt
                            dry run in the smoke workflow
```

## How an install works

1. Boot the image. The live system starts `patina21-ui.service`: an X session on tty7
   with Calamares full screen, branded patina21. The console shows `branding/logo.txt`.
2. Calamares asks what it must: time zone and keyboard (pre-filled), disk (erase is
   preselected; encryption and manual partitioning are available) and the user. The
   summary page is the last look before anything is written.
3. The live system is copied to disk (`unpackfs`), then Plasma and the base bundle are
   fetched from Debian's mirrors into it (`packages`, the list in
   `modules/packages.conf`), the live tooling and Calamares are removed from it, the
   first-boot unit is enabled (`shellprocess-firstboot.conf`), GRUB is installed with
   Debian's signed shim.
4. First boot: the service takes tty1 before the login screen, clones this repository
   into the user's `~/.local/share/patina21`, links `~/.local/bin/patina` and runs
   `patina install`, which asks the remaining question, the theme. Then it writes
   `/var/lib/patina21/firstboot-done` and never runs again. A failed clone or install
   prints the Path A command to run by hand and still marks the boot done, so a machine
   never loops on first boot.

That is Path A, executed for the user. The image carries only the installer, its
configuration, the network stack and firmware, so it stays well under a gigabyte and
Debian's mirrors carry the download, not us. The installed system is current Debian
stable at install time, and an old image installs today's layer.

## Building

`.github/workflows/iso-build.yml` does it for both architectures: `iso/live/build.sh
<arch>` in a privileged Debian 13 container on an x86_64 and on an aarch64 runner (a
native build on each, no emulation), then the boot test on a plain runner of the same
architecture, then, for a `v*` tag, the upload of both images to that tag's GitHub
release (created as a draft when missing). The workflow also runs on every pull request
that touches `iso/`, `branding/`, the base bundle or the workflow itself, so an image
change is built and booted before it is merged; it publishes only from a tag. To build by
hand on a Debian machine of the target architecture:

```sh
sudo apt-get install live-build debootstrap
sudo iso/live/build.sh amd64            # writes iso/build/live/patina21-amd64.hybrid.iso
sudo iso/live/build.sh arm64            # on an arm64 machine
```

`build.sh` renders `branding/logo.txt` into `/etc/issue.d` and into the installer's
`logo.svg`, and fills the version into `branding.desc` with `yq`, so nothing generated
is committed and the logo keeps its single copy.

## The release gate

- Automated: `test/boot-test.sh <iso>` boots the image in QEMU with the serial console
  attached and waits for `patina21 installer: ready`, which `.xinitrc` prints once
  Calamares is running. It proves the image, the kernel, the initrd and the installer
  session; the workflow runs it before any upload. It uses KVM where the runner has it
  and falls back to emulation (TCG) where it does not, with a longer timeout; GitHub's
  arm64 runners have no KVM, so the arm64 test is the slow one. The kernel is loaded by
  QEMU directly, so the test does not cover GRUB and shim; the manual install does.
- Manual, once per release: one real install in a VM through the installer, then a first
  boot that ends in `patina21 firstboot: done`. Calamares has no unattended mode, so
  this part is not automated; the roadmap keeps it as an open Phase 2 item.
- A failing build or test is simply not published; Path A users are never affected.

## Rules

- Every package comes from Debian's archive. The image adds only the installer
  configuration, the installer screen and branding within Debian's trademark policy
  (`docs/branding.md`). Firmware from `non-free-firmware` is the only non-free content.
- Debian's signed kernel, shim and GRUB stay untouched so Secure Boot keeps working. No
  kernel patches, no out-of-tree modules.
- The first-boot contract for `patina install` (Phase 1): honour `PATINA_UNATTENDED=1`
  (no prompts, defaults for everything) and `PATINA_THEME=<name>`, and exit non-zero on
  failure so the first-boot script can say so.

## To verify on the first build

- Package names are checked by the smoke workflow's apt dry run on every pull request;
  what it cannot check is whether the set is complete. The first boot of the image tells.
- `--uefi-secure-boot enable` and `--bootloaders grub-efi` are live-build options whose
  exact spelling changed across releases; compare with `lb config --help` on Debian 13.
- Calamares' module options follow the 3.3 series as Debian 13 packages it. The
  `users.conf` group syntax, `displaymanager.conf` and the `style` keys in
  `branding.desc` are the ones most likely to need a rename.
- Calamares runs as root inside `dbus-run-session`; if it insists on a polkit agent or a
  system bus, `.xinitrc` is the place to fix it.
- The `packages` module needs working DNS inside the target; Calamares' `mount` module
  binds `/run` and `/etc/resolv.conf` on Debian's own live images, so it should here.
- `grub-install` picks the signed images only when `grub-efi-amd64-signed` and
  `shim-signed` are present in the target; they come from the live system
  (`live/arch/amd64.list.chroot`) and must survive the `remove` list.
- `boot-test.sh` takes kernel and initrd from `live/` on the image and expects `-display
  none -vga std` to leave X a framebuffer to start on.
