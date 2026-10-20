# CLAUDE.md

Context and rules for anyone, human or Claude, working in this repository. Read it fully
before changing anything. The README is for users; this file is for contributors.

## What patina21 is

A polish layer for KDE Plasma on openSUSE: themes, cross-app consistency, curated
defaults, agent CLIs and a free-software, EU-sovereign app stack. Delivered as a layer on
stock openSUSE (Path A: `git clone` plus `patina install`) and as an ISO that only
automates Path A (Path B). Inspired by Omarchy's polish and update model, not by its tiling
UX, kernel or package repository. Not a distribution, not a fork of openSUSE.

Maintainer: one person, a few hours a week. Community contributions are mostly theme
packs. Audience: developers and privacy-minded users in the EU.

## Decisions already made (do not re-litigate)

- Desktop: KDE Plasma first. Hyprland is a possible later add-on, so themes and
  keybindings are desktop-agnostic data rendered per desktop (`desktops/`).
- Base: openSUSE Tumbleweed is the first and reference base; Leap is a planned second
  flavour. Fedora possible later, not a priority. CachyOS and Ubuntu were rejected.
- Priorities, in order: free-software purity, hardware and ARM reach, lowest maintenance
  burden, package freshness.
- Sources: openSUSE repos first, Flathub for GUI apps we do not track, upstream installers
  (npm, uv) for the agent CLIs (Claude Code, Codex CLI, opencode, Ollama).
- App stack: Nextcloud client, Collabora Office or OnlyOffice (still open), Thunderbird,
  Element, KeePassXC.
- Install model: per user, Omarchy-style. Clone at `~/.local/share/patina21`, symlink
  `~/.local/bin/patina`, state in `~/.local/state/patina21/`. `PATINA_PATH` overrides.
- Updates: `git pull` plus versioned migrations (`migrations/`).
- ISO: Agama autoinstall profile plus a KIWI description built on the Open Build Service,
  and a first-boot service that runs the same `patina install`. Secure Boot through
  openSUSE's signed kernel and shim. Published only after an automated VM install test.
- ARM: aarch64 is first-class from day one. An "ARM version" is a tested-hardware list
  plus device glue under `devices/`, never a separate release or branch.
- License: GPL-3.0-or-later. Theme artwork may carry its own license (`artwork_license`).
- Data format: YAML, parsed with `yq` (the Go implementation packaged by openSUSE).
- The name is final. The 21 is not explained anywhere except by the README FAQ answer.

## Principles (non-negotiable)

1. Own the UI, own nothing that gets CVEs: no kernel, no rebuilt packages, no own package
   repository, no own binaries. Every package comes from openSUSE repos, Flathub or an
   upstream installer. Security is the base's job.
2. Data over code: themes, keybindings and package lists are data files. Scripts are thin,
   bash, shellcheck-clean. Prefer configuration over software we must maintain.
3. Base-agnostic layer: a package manifest with per-backend mappings (zypper first; apt,
   dnf, pacman later). Nothing is architecture-specific outside `devices/`.
4. Updates are `git pull` plus versioned migrations.
5. The ISO contains no logic of its own; it only automates the stock-openSUSE path. If
   Path A and Path B diverge, Path A wins.
6. Every design choice must reduce ongoing work for one person.

## Never

- build or rebuild packages, add a package repository, commit executables or firmware,
  patch a kernel, add out-of-tree modules
- add architecture- or device-specific code or data outside `devices/`
- add proprietary software, US cloud services or snap as defaults
- put logic into the ISO that Path A does not have
- add a dependency beyond bash, coreutils, git, `yq` and what the base ships without a
  line in `manifest/` and a reason in the commit message
- add abstraction layers, plugin systems, frameworks or a second language for the tooling
- write "openSUSE patina21", "patina21 Linux" or `Patina21`
- explain the 21

## Repository map

| Directory | Holds |
|---|---|
| `bin/` | the `patina` entry point; `bin/patina-<cmd>` per subcommand, thin bash |
| `themes/` | theme packs as data; `_template/` is the skeleton |
| `defaults/` | desktop-agnostic keybindings and curated settings |
| `desktops/` | per-desktop renderers (templates plus one `apply.sh`); `plasma/` first |
| `manifest/` | bundles, backends, upstream recipes: everything that gets installed |
| `migrations/` | timestamped, idempotent update steps |
| `devices/` | the only place for device- or architecture-specific files |
| `iso/` | Agama profile, KIWI description, first-boot unit (Phase 2) |
| `docs/` | roadmap, branding and trademark rules, tested hardware |
| `.github/workflows/` | lint (shellcheck, yamllint) and smoke (Tumbleweed containers, x86_64 and aarch64) |

Each directory's README is the authority on its file format.

## Naming

- `patina21`: always lowercase, also at the start of a sentence. Command: `patina`.
- Environment variables: `PATINA_` prefix. State and config directories: `patina21`.
- Files, directories, themes, devices, bundles: lowercase kebab-case.
- Scripts in `bin/`: `patina-<cmd>`, no extension. Other scripts: `.sh`.
- Data files end in `.yaml`; GitHub workflows keep GitHub's `.yml`.
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
- Read YAML with `yq`; never parse it with grep or sed. Write user config under XDG
  directories, never into the repository checkout.
- Short, obvious code beats clever code. A function used once is not a function.
- One data file per concern; no generated files committed.

## Data formats

- Theme: `themes/<name>/theme.yaml`, base16 palette keys. See `themes/README.md`.
- Keybindings and settings: `defaults/*.yaml`. See `defaults/README.md`.
- Packages: `manifest/bundles/*.yaml`, `manifest/backends/*.yaml`, `manifest/upstream.yaml`.
  Canonical package names are openSUSE's. See `manifest/README.md`.
- Devices: `devices/<slug>/device.yaml`. See `devices/README.md`.
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
   `installed` and `map` (canonical openSUSE name to this backend's name, only where they
   differ). Copy `zypper.yaml` as the model.
2. Do not touch the bundles: canonical names stay openSUSE's.
3. Add a container for that base to `.github/workflows/smoke.yml` so the bootstrap runs
   there on both architectures.
4. Document the base's status in the README table. New backends come only after Path A
   and the ISO are stable on openSUSE (see the roadmap).

## How to add a device

1. Only once the device boots openSUSE. `cp -r devices/_template devices/<slug>`; fill
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
