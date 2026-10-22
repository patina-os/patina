# CLAUDE.md

Context and rules for anyone, human or Claude, working in this repository. Read it fully
before changing anything. The README is for users; this file is for contributors.

## What patina21 is

A polish layer for KDE Plasma on Debian: themes, cross-app consistency, curated defaults,
agent CLIs and a free-software, EU-sovereign app stack. Delivered as a layer on stock
Debian (Path A: `git clone` plus `patina install`) and as a live image that only automates
Path A (Path B). Inspired by Omarchy's polish, its quick branded install and its update
model, not by its tiling UX, kernel or package repository. Not a distribution, not a fork
of Debian.

Maintainer: one person, a few hours a week. Community contributions are mostly theme
packs. Audience: developers and privacy-minded users in the EU.

## Decisions already made (do not re-litigate)

- Desktop: KDE Plasma first. Hyprland is a possible later add-on, so themes and
  keybindings are desktop-agnostic data rendered per desktop (`desktops/`).
- Base: Debian stable (Debian 13 "trixie" today) is the first and reference base. It
  replaced openSUSE Tumbleweed before anything shipped: third-party installers, vendor
  packages and manuals assume apt, and Debian serves the three top priorities at least
  as well. openSUSE is a possible later base; its backend file stays as untested data.
  Fedora possible later, not a priority. Ubuntu (snap) and CachyOS were rejected.
- Priorities, in order: free-software purity, hardware and ARM reach, lowest maintenance
  burden, package freshness.
- Sources: Debian's `main` archive first (plus `non-free-firmware` for firmware only, the
  same blobs every base ships), Flathub for GUI apps we do not track, upstream installers
  (npm, uv, a release binary, an upstream's own signed apt repository for an opt-in
  tool) for the agent tools and for the Go `yq`, which Debian does not package. An
  upstream's signed apt repository may serve a default only when the software is free
  and neither Debian's archive nor Flathub carries it (Euro-Office today); the recipe
  moves to Flathub as soon as Flathub carries it.
- App stack: Nextcloud client, Euro-Office (the AGPL fork of ONLYOFFICE by a European
  consortium, from Nextcloud's signed apt repository until Flathub carries it), Thunderbird,
  Element, KeePassXC, kitty as the terminal (Ghostty once Debian carries it), the
  developer tools from Debian's archive and Zed from Flathub, all in the default desktop
  bundle. Agent tools (Claude Code, Codex CLI, opencode, Claude Desktop, Ollama) are an
  opt-in bundle because most of them are proprietary; Ollama is the local backend they
  point at, and their desktop integration is a shortcut and a terminal profile, as data.
- Look: the first theme is amethyst, purple, continuing the logo's pink-to-purple
  gradient, with generated abstract artwork (SVG in the theme, rendered at apply time)
  licensed with the repository. No third-party wallpapers. The `agent` shortcut opens
  opencode by default (`defaults/settings.yaml`), the free one of the agent CLIs. One
  look from the boot menu to the desktop: the installer, the boot menu, the login
  screen and the Plasma splash take their colours from the default theme's palette at
  build or apply time, never by hand; the words are set in Inter, details (versions,
  hostnames, progress, terminals) in JetBrains Mono, both from Debian's archive. Two
  marks: the ASCII wordmark on terminals, the typeset wordmark patina²¹
  (`branding/wordmark.svg`) on screens, never both on one surface.
  The desktop's shape is a centred bar as on Windows 11 and new windows centred at one
  size; both are knobs in `defaults/settings.yaml`. No automatic tiling on Plasma:
  that would need a KWin script Debian does not package; a tiling desktop is the
  Hyprland add-on.
- Speed: the system tuning CachyOS ships as configuration (zram, I/O schedulers, memory
  sysctls, journald and systemd limits, boot) is copied as data for every install, kept
  under `defaults/system/`; its kernel, rebuilt packages and own repository are not.
  Plasma-side speed settings are curated defaults like any other.
- Install model: per user, Omarchy-style. Clone at `~/.local/share/patina21`, symlink
  `~/.local/bin/patina`, state in `~/.local/state/patina21/`. `PATINA_PATH` overrides.
- Updates: `git pull` plus versioned migrations (`migrations/`).
- Image: a small live image built with Debian's live-build, with Calamares as the branded
  installer. The live system carries only the installer; Plasma and the base packages
  are fetched from Debian's mirrors during the install, so the image stays under one
  gigabyte and the installed system is current. Built in GitHub Actions, booted in QEMU
  in CI, published as a GitHub release asset only after that boot test and one manual
  install check. Secure Boot through Debian's signed shim, GRUB and kernel. First boot
  runs the same `patina install` as Path A.
- ARM: aarch64 is first-class from day one. An "ARM version" is a tested-hardware list
  plus device glue under `devices/`, never a separate release or branch.
- License: GPL-3.0-or-later. Theme artwork may carry its own license (`artwork_license`).
- Data format: YAML, parsed with the Go `yq` (mikefarah). Debian's `yq` package is the
  Python jq wrapper and must not be used.
- The name is final. The 21 is not explained anywhere except by the README FAQ answer.

## Principles (non-negotiable)

1. Own the UI, own nothing that gets CVEs: no kernel, no rebuilt packages, no own package
   repository, no own binaries. Every package comes from Debian's archive, Flathub or an
   upstream installer. Security is the base's job.
2. Data over code: themes, keybindings, package lists and the installer's configuration
   are data files. Scripts are thin, bash, shellcheck-clean. Prefer configuration over
   software we must maintain.
3. Base-agnostic layer: a package manifest with per-backend mappings (apt first; zypper
   kept as data; dnf, pacman later). Nothing is architecture-specific outside `devices/`.
4. Updates are `git pull` plus versioned migrations.
5. The image contains no logic of its own; it only automates the stock-Debian path. If
   Path A and Path B diverge, Path A wins.
6. Every design choice must reduce ongoing work for one person.

## Never

- build or rebuild packages, add a package repository of our own, commit executables or
  firmware, patch a kernel, add out-of-tree modules
- add architecture- or device-specific code or data outside `devices/` and the
  per-architecture package lists under `iso/live/arch/`
- add proprietary software, US cloud services or snap as defaults
- put logic into the image that Path A does not have
- add a dependency beyond bash, coreutils, git, `yq` and what the base ships without a
  line in `manifest/` and a reason in the commit message
- add abstraction layers, plugin systems, frameworks or a second language for the tooling
- write "Debian patina21", "patina21 Linux" or `Patina21`
- paste the logo into a script or redraw it; `branding/logo.txt` is the only copy of the
  text mark and `branding/wordmark.svg` the only copy of the typeset one; scripts print
  or copy them (`print_logo` in `lib.sh`, the image build and the renderer copy the SVG)
- explain the 21

## Repository map

| Directory | Holds |
|---|---|
| `bin/` | the `patina` entry point; `bin/patina-<cmd>` per subcommand, thin bash; `lib.sh` holds the few functions they share, among them the theme loader and template filler the renderers and the image build use |
| `branding/` | the marks as data: `logo.txt` is the ASCII wordmark scripts print, `wordmark.svg` and `wave.svg` the marks screens show |
| `themes/` | theme packs as data; `_template/` is the skeleton |
| `defaults/` | desktop-agnostic keybindings and curated settings; `apps.yaml` the settings merged into apps' own files; `system/` the system tuning files |
| `desktops/` | per-desktop renderers (templates, an `actions.yaml` for the keybindings, one `apply.sh`) and the headless session the desktop workflow screenshots (`screenshot.sh`); `plasma/` first |
| `manifest/` | bundles, backends, upstream recipes: everything that gets installed |
| `migrations/` | timestamped, idempotent update steps |
| `devices/` | the only place for device- or architecture-specific files |
| `iso/` | live-build configuration, Calamares configuration and branding, the templates `iso/live/assets.sh` renders from the theme (installer artwork and stylesheet, boot menu theme), first-boot unit, QEMU boot test (Phase 3) |
| `docs/` | roadmap, branding and trademark rules, tested hardware; `screenshots/` holds the installer and desktop screenshots the README shows, taken by the image's boot test and by the desktop workflow's headless Plasma session, refreshed per release |
| `.github/workflows/` | lint (shellcheck, yamllint), smoke (Debian containers, x86_64 and aarch64), desktop (Path A plus a Plasma X11 session on a virtual framebuffer, screenshot), iso (build, boot test, release) |

Each directory's README is the authority on its file format.

## Naming

- `patina21`: always lowercase, also at the start of a sentence. Command: `patina`.
- Environment variables: `PATINA_` prefix. State and config directories: `patina21`.
- Files, directories, themes, devices, bundles: lowercase kebab-case.
- Scripts in `bin/`: `patina-<cmd>`, no extension. Other scripts: `.sh`.
- Data files end in `.yaml`; GitHub workflows keep GitHub's `.yml`; Calamares keeps its
  `.conf` and `branding.desc` names and live-build its `.list.chroot` names, because the
  tools require them. They are YAML all the same and are linted as such. The files under
  `defaults/system/` are the exception: sysctl, udev and systemd files named by their
  destination, excluded from the YAML checks.
- Entries starting with `_` are templates; tools skip them.

## Coding conventions

- Bash only. First line `#!/usr/bin/env bash`, second line
  `# SPDX-License-Identifier: GPL-3.0-or-later`, then a one-line purpose comment, then
  `set -euo pipefail`.
- shellcheck-clean, with no disabled warning unless a comment says why.
- 2-space indent (`.editorconfig`), `[[ ]]`, quoted variables, `local` in functions, no
  `eval`, no `curl | sh` except an upstream installer listed in `manifest/upstream.yaml`.
- Idempotent: every script may run twice without harm. Check before changing.
- `sudo` appears only in backend commands from `manifest/backends/`, never elsewhere.
  System files are written only through that path (`system.write`), only from
  `defaults/system/`, for the keyring and sources file of an `apt-source` recipe, and
  for the login screen's wallpaper and the Breeze SDDM theme's `theme.conf.user`
  (`/usr/local/share/patina21/login.png`, written by the desktop renderer).
  The scripts drop the `sudo` when they already run as root (a container, first boot).
- Desktop configuration is written only by `desktops/<desktop>/apply.sh`, through the
  desktop's own tool (`kwriteconfig6` on Plasma) and only when a value differs, so a
  second run changes nothing. Generated files carry the theme's name and the renderer
  removes those of other themes.
- Read YAML with `yq`; never parse it with grep or sed. Write user config under XDG
  directories, never into the repository checkout.
- Short, obvious code beats clever code. A function used once is not a function.
- One data file per concern; no generated files committed. The one exception is
  `docs/screenshots/`: images CI produces, committed as they come, never edited.

## Data formats

- Theme: `themes/<name>/theme.yaml`, base16 palette keys. See `themes/README.md`.
- Keybindings and settings: `defaults/*.yaml`. See `defaults/README.md`.
- Packages: `manifest/bundles/*.yaml`, `manifest/backends/*.yaml`, `manifest/upstream.yaml`.
  Canonical package names are Debian's. See `manifest/README.md`.
- Devices: `devices/<slug>/device.yaml`. See `devices/README.md`.
- Image: `iso/live/` (live-build lists and Calamares configuration). See `iso/README.md`.
- Validate with `yq eval '.' <file>` and `yamllint .`.

## How to add a theme

1. `cp -r themes/_template themes/<name>`; set `name` to `<name>`.
2. Fill the palette (base16 keys; copying a tinted-theming scheme's `palette` block
   works), add wallpapers you may redistribute, set `artwork_license`.
3. Keep it desktop-agnostic; Plasma-only hints go under the `plasma:` key as data.
4. No scripts in a theme. If a theme needs code, the renderer is missing a feature: add it
   to `desktops/<desktop>/` for all themes.
5. Validate the YAML, add a `CHANGELOG.md` line, open a pull request.

## How to add a base backend

1. Create `manifest/backends/<backend>.yaml` with `os_ids`, `refresh`, `install`,
   `installed` and `map` (canonical Debian name to this backend's name, only where they
   differ). Copy `apt.yaml` as the model.
2. Do not touch the bundles: canonical names stay Debian's.
3. Add a container for that base to `.github/workflows/smoke.yml` so the bootstrap runs
   there on both architectures.
4. Document the base's status in the README table. New backends come only after Path A
   and the image are stable on Debian (see the roadmap).

## How to add a device

1. Only once the device boots Debian. `cp -r devices/_template devices/<slug>`; fill
   `device.yaml` with facts; `status: untested` is fine.
2. Express device-specific needs as data (`kernel_params`, `extra_packages`). Glue scripts
   only when data cannot express it (firmware extraction), following the `bin/`
   conventions; they run only when `patina` detects that device.
3. Add a row to `docs/hardware.md`. Never create an ARM branch or a separate release.

## How to add a migration

1. `cp migrations/_template.sh migrations/$(date -u +%Y%m%d%H%M)-<slug>.sh`.
2. One change, idempotent, no prompts, a backup before any destructive step.
3. A fresh `patina install` must produce the same end state without the migration.

## Before committing

- `shellcheck` every script, `yamllint .`, `yq eval '.'` on changed YAML,
  and `bin/patina help` still works.
- Update `CHANGELOG.md` under Unreleased for anything user-visible.
- Commit messages: imperative subject under 72 characters, body explains why.
- No files outside the layout above without updating the repository map here.
