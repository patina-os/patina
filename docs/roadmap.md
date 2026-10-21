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

Scaffolded in `iso/`; nothing built or booted yet. Phase 2 can be prepared next to
Phase 1 because it only automates Path A, but it is done only after Phase 1 is.

- [x] live-build configuration: a small live system that carries only Calamares, the
  network stack and firmware; Plasma and the base bundle are fetched from Debian's
  mirrors during the install
- [x] Calamares configuration and branding as data: disk, user, locale and keyboard
  pages; first boot asks the theme
- [x] first-boot unit and script that run the same `patina install` as Path A
- [x] `iso-build` workflow: build in a Debian container, boot test in QEMU, upload to the
  GitHub release of a tag only when the boot test passed
- [ ] the first image builds and passes the boot test on x86_64
- [ ] one manual install in a VM per release, until Calamares can be driven unattended
  (upstream has no unattended mode; see `iso/README.md`)
- [x] branding within Debian's trademark policy (`docs/branding.md`, the logo)
- Done when: boot, answer the installer, finished desktop identical to Path A.

## Phase 3: aarch64 (Raspberry Pi 4 first)

- manual validation on a Raspberry Pi 4 (Debian's official Raspberry Pi image, USB SSD,
  clean reimage per run), then Path A on it; the goal is correctness, not UX
- the live image for arm64 (`iso/live/arch/arm64.list.chroot`) for machines that boot a
  generic UEFI Debian
- Done when: Path A passes on the Pi 4 and the arm64 image passes the boot test.

## Phase 4: ARM laptops, as hardware allows

Per-device glue under `devices/`, only once a device boots Debian's kernel, in the
expected order: Snapdragon X Elite (works with caveats upstream), Snapdragon X2 Elite
(upstreaming in progress), Nvidia RTX Spark / N1X laptops (no public Linux image yet).
Each one gets a row in `docs/hardware.md`. Apple Silicon is out of scope (Fedora Asahi,
not Debian).

## Later, unscheduled

- Debian 14 when it becomes stable (same layer; a migration if Plasma's config moved)
- Hyprland as an add-on desktop (`desktops/hyprland/`), never the default
- zypper (openSUSE), dnf and pacman backends, only after Path A and the image are stable

## Non-goals

Own kernel, own package repository, rebuilt packages, own binaries, proprietary or
US-cloud defaults, snap, Hyprland-first UX, Apple Silicon, supporting bases other than
Debian before Path A and Path B are stable, a separate "ARM edition".
