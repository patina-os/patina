# Roadmap

patina21 ships in phases. Each phase ends with something a user can run, and nothing in a
later phase may break an earlier one. Path A (stock Debian plus `patina install`) is the
reference path and must work at every point.

Status: pre-alpha. Nothing below is done.

## Phase 1: Path A on x86_64 (Debian 13)

- `patina install` TUI: theme, app bundles, Nextcloud, agent tools; it honours
  `PATINA_UNATTENDED=1` and `PATINA_THEME` so the image's first boot can run it
- `patina update` (git pull plus migrations), `patina theme`, `patina doctor`
- apt backend, Flathub, upstream installers (npm, uv, the Go `yq` release binary,
  Anthropic's apt repository for the opt-in Claude Desktop)
- the Plasma renderer and the first theme(s), against Plasma 6.3 as Debian 13 ships it
- CI: shellcheck and yamllint; bootstrap smoke test in Debian 13 containers on x86_64
  and aarch64 runners (the ARM plan's phase 1 happens here)
- Done when: a fresh Debian-13-with-Plasma VM becomes a finished desktop with one
  command, a second run changes nothing, and an update from the previous tag works.

Open decisions for this phase: TUI helper (`gum` or `dialog`, both in Debian), office
suite (Collabora Office or OnlyOffice), name and palette of the first theme.

## Phase 2: the live image on x86_64 (live-build, Calamares)

The image builds and boots (`iso/`); the manual install waits for Phase 1, because the
first boot runs `patina install`. Phase 2 can be prepared next to Phase 1 because it
only automates Path A, but it is done only after Phase 1 is.

- [x] live-build configuration: a small live system that carries only Calamares, the
  network stack and firmware; Plasma and the base bundle are fetched from Debian's
  mirrors during the install
- [x] Calamares configuration and branding as data: disk, user, locale and keyboard
  pages; first boot asks the theme
- [x] first-boot unit and script that run the same `patina install` as Path A
- [x] `iso-build` workflow: build in a Debian container, boot test in QEMU, upload to the
  GitHub release of a tag only when the boot test passed
- [x] the first image builds and passes the boot test on x86_64 (the `iso` workflow,
  on every pull request that touches the image)
- [ ] one manual install in a VM per release, until Calamares can be driven unattended
  (upstream has no unattended mode; see `iso/README.md`)
- [x] branding within Debian's trademark policy (`docs/branding.md`, the logo)
- Done when: boot, answer the installer, finished desktop identical to Path A.

## Phase 3: aarch64 (Raspberry Pi 4 first)

- [ ] manual validation on a Raspberry Pi 4 (Debian's official Raspberry Pi image, USB
  SSD, clean reimage per run), then Path A on it; the goal is correctness, not UX. The
  procedure is in `devices/raspberry-pi-4/README.md`; it needs Phase 1's
  `patina install` and the hardware
- [x] the live image for arm64 (`iso/live/arch/arm64.list.chroot`) for machines that
  boot a generic UEFI Debian: built natively on GitHub's aarch64 runners and boot-tested
  in QEMU by the same `iso` workflow
- Done when: Path A passes on the Pi 4 and the arm64 image passes the boot test.

## Phase 4: ARM laptops, as hardware allows

Per-device data under `devices/`, only once a device boots Debian's kernel, in the
expected order. Each one has a row in `docs/hardware.md`. Apple Silicon is out of scope
(Fedora Asahi, not Debian).

- [x] Snapdragon X Elite: `devices/snapdragon-x-elite/`, data only, status untested.
  Debian 13 runs on them from the kernel and firmware in `trixie-backports`, installed
  by hand (the Debian wiki documents the ThinkPad T14s Gen 6); the live image cannot
  boot them, because the boot loader has to pass the model's device tree. Debian's
  firmware package covers two Lenovo models; the rest need firmware from their Windows
  partition
- [ ] one run of Path A on a Snapdragon X Elite laptop (the procedure is in that
  directory's README); it needs Phase 1's `patina install` and the hardware. The
  firmware helper for the models Debian's archive does not cover is written after that
  run, from what it shows missing
- [ ] Snapdragon X2 Elite: waiting for upstream. Device trees land in Linux 7.4, GPU and
  NPU drivers are still upstreaming, Debian 13's kernel is 6.12; Qualcomm announced
  Debian support for late 2026. No device directory until one boots Debian's kernel
- [ ] Nvidia RTX Spark laptops (N1X): waiting for upstream. On sale since October 2026,
  Windows only, no Linux commitment from Nvidia. Community bring-ups run on patched 7.x
  kernels with Nvidia's open driver; the platform patches are not upstream, Debian 13's
  kernel is 6.12. No device directory until one boots Debian's kernel
- Done when: Path A passes on one Snapdragon X Elite laptop with Debian's own kernel.

## Later, unscheduled

- Debian 14 when it becomes stable: the same layer. What changes is data: the
  distribution name in `iso/live/auto/config`, the `debian:13` container tags in the
  `smoke` and `iso` workflows, the firmware list of the live image, the Plasma version
  the renderer targets, and a migration only if Plasma's configuration moved. The apt
  backend serves every Debian release as it is
- Hyprland as an add-on desktop (`desktops/hyprland/`, the contract is written), never
  the default. It waits for Debian 14: Debian 13 carries Hyprland only in
  `trixie-backports`, and the manifest installs from the main archive only. The rest of
  its stack is in Debian 13 already
- zypper (openSUSE), dnf (Fedora) and pacman (Arch) backends: kept as untested data under
  `manifest/backends/`, with the name maps for today's bundles. A smoke container and a
  README row with a status come only after Path A and the image are stable on Debian

## Non-goals

Own kernel, own package repository, rebuilt packages, own binaries, proprietary or
US-cloud defaults, snap, Hyprland-first UX, Apple Silicon, supporting bases other than
Debian before Path A and Path B are stable, a separate "ARM edition".
