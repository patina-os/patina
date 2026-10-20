# Roadmap

patina21 ships in phases. Each phase ends with something a user can run, and nothing in a
later phase may break an earlier one. Path A (stock openSUSE plus `patina install`) is the
reference path and must work at every point.

Status: pre-alpha. Nothing below is done.

## Phase 1: Path A on x86_64 (openSUSE Tumbleweed)

- `patina install` TUI: theme, app bundles, Nextcloud, agent CLIs
- `patina update` (git pull plus migrations), `patina theme`, `patina doctor`
- zypper backend, Flathub, upstream installers for the agent CLIs
- the Plasma renderer and the first theme(s)
- CI: shellcheck and yamllint; bootstrap smoke test in Tumbleweed containers on x86_64
  and aarch64 runners (the ARM plan's phase 1 happens here)
- Done when: a fresh Tumbleweed-with-Plasma VM becomes a finished desktop with one
  command, a second run changes nothing, and an update from the previous tag works.

Open decisions for this phase: TUI helper (`gum` or `dialog`, both from openSUSE repos),
office suite (Collabora Office or OnlyOffice), name and palette of the first theme.

## Phase 2: ISO on x86_64 via the Open Build Service

- Agama autoinstall profile (disk, user, theme) and KIWI description in `iso/`
- OBS project owned by the patina21 account; automatic rebuild and signing
- first-boot service that runs the same `patina install` as Path A
- QEMU install test in CI; the release rule from `iso/README.md`
- branding within the openSUSE trademark guidelines (`docs/branding.md`)
- Done when: boot, three questions, finished desktop identical to Path A.

## Phase 3: aarch64 images (Raspberry Pi 4 first)

- manual validation on a Raspberry Pi 4 (openSUSE's official image, USB SSD, clean
  reimage per run); the goal is correctness, not UX
- KIWI aarch64 targets: a Pi 4 image like openSUSE's own
- an aarch64 ISO for laptops that already boot openSUSE cleanly
- Done when: the Pi 4 image passes the same install test as the x86_64 ISO.

## Phase 4: ARM laptops, as hardware allows

Per-device glue under `devices/`, only once a device boots openSUSE, in the expected
order: Snapdragon X Elite (works with caveats today), Snapdragon X2 Elite (upstreaming in
progress), Nvidia RTX Spark / N1X laptops (no public Linux image yet). Each one gets a row
in `docs/hardware.md`. Apple Silicon is out of scope (Fedora Asahi, not openSUSE).

## Later, unscheduled

- openSUSE Leap as a second flavour (same layer, slower base)
- Hyprland as an add-on desktop (`desktops/hyprland/`), never the default
- apt, dnf and pacman backends, only after Path A and the ISO are stable

## Non-goals

Own kernel, own package repository, rebuilt packages, own binaries, proprietary or
US-cloud defaults, snap, Hyprland-first UX, Apple Silicon, supporting bases other than
openSUSE before Path A and Path B are stable, a separate "ARM edition".
