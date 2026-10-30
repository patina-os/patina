# CLAUDE.md

Context and rules for anyone, human or Claude, working in this repository. Read it fully
before changing anything. The README is for users; this file is for contributors.

## What patina is

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
  tool) for the agent tools and for the Go `yq`, which Debian does not package, and the
  tagged release of patina's own kortex through its install script (the `git` method).
  An
  upstream's signed apt repository may serve a default only when the software is free
  and neither Debian's archive nor Flathub carries it (Euro-Office today); the recipe
  moves to Flathub as soon as Flathub carries it. An opt-in app that is free and that
  neither Debian's archive nor Flathub carries may come from its upstream's release
  (the ArtCraft Launcher, chosen by the maintainer in October 2026); it too moves as
  soon as one of them carries it. Opt-in tools that wait for a package instead: cliamp.
  Deferred in October 2026, to decide later: FileAction (MIT, Metamorfolog/file_action,
  a converter on a radial wheel) as an opt-in app from its release. Its release ships
  only an x86_64 tarball (no aarch64, and the `binary` method takes one file, so it
  waits for an arm64 build and an AppImage upstream), it does not update itself on
  Linux, and its Office conversions need LibreOffice beside Euro-Office.
- App stack: Nextcloud client, Euro-Office (the AGPL fork of ONLYOFFICE by a European
  consortium, from Nextcloud's signed apt repository until Flathub carries it), Thunderbird,
  Element, KeePassXC, kitty as the terminal (Ghostty once Debian carries it), Firefox ESR
  (its telemetry, Pocket and sponsored content off by policy), Okular, Gwenview and
  Haruna and the developer tools from Debian's archive, all in the default desktop
  bundle; Zed and Tauon (the music player) from Flathub are the opt-in `extras` bundle,
  because their runtimes add over 2 GB (October 2026, after the first VM run). The
  `minimal` bundle (kitty and Firefox ESR) is the small alternative to desktop; the look
  (fonts, icons) is part of base, so every install has it. The ArtCraft suite (free,
  alpha counterparts of Adobe's and Microsoft's apps) is the opt-in `artcraft` bundle:
  its launcher, which installs and updates the apps the user picks. Gaming is not a
  focus. Agent tools (Claude Code, Codex CLI, opencode, Claude Desktop, Ollama) are an
  opt-in bundle because most of them are proprietary; Ollama is the local backend they
  point at, and their desktop integration is a shortcut and a terminal profile, as data.
  The app bundles, the theme and the AI agent are questions of the install and pages of
  the installer, so the image's first boot asks nothing more (but a cloud agent's
  provider and key). The AI agent: opencode, a
  free agent, with a model Ollama runs on the machine, with a cloud provider the user
  picks (European ones first, the key in opencode's own login) or none (the default:
  the agent is opt-in, `patina ai on` turns it on later), as the `ai-local` and
  `ai-cloud` bundles. It asks before every change
  (`defaults/apps.yaml`) and reads `defaults/agent.md`. It runs what needs root with
  `sudo -A`, through a password dialog in the theme's colours. The services it works
  with are MCP presets (Linear, Notion, GitHub, Nextcloud), off until `patina ai
  connect` turns one on; a token is asked for on a terminal and kept in a file only the
  user can read (October 2026). Its place in the command
  palette is kortex, a KRunner runner kept in a repository of its own
  (`patina-os/kortex`), which may use what patina's tooling may not (it is Python);
  both AI bundles install its tagged release, pinned in `manifest/upstream.yaml`.
- Look: the default theme is aurora, made for OLED screens (October 2026, after the
  redesign whose eight directions `docs/design/futures.html` keeps): true black with
  panels one step above it, neon green as the accent and violet as the second colour.
  Its wallpaper is a Google DeepMind visualisation from Pexels (`deepmind.jpg`, under
  the Pexels licence, credited in `themes/aurora/README.md`), and the light mode's is
  a white one of the same series (`deepmind-light.jpg`): the two third-party
  wallpapers, chosen by the maintainer in October 2026; a contour map that glows green
  at the summit and turns violet at the edges is the second (SVG in the theme,
  rendered at apply time, licensed with the repository).
  Dark is the default mode; aurora carries a light mode as data (a `light:` block),
  switched with `patina theme mode`, and the boot menu, the installer, the splash and
  the login screen stay dark in either. datum (graphite, ice, coral) stays as an
  option; amethyst, the first theme, was removed in October 2026. No other third-party artwork. Artwork drawn by a
  script is committed as the SVG it produced, never with the script. The `agent`
  shortcut opens opencode by default (`defaults/settings.yaml`), the free one of the
  agent CLIs. One look from the boot menu to the desktop: the installer, the boot
  menu, the login screen and the Plasma splash take their colours from the default
  theme's palette at build or apply time, never by hand; the words are set in Source
  Sans 3, details (versions, hostnames, progress, terminals) in JetBrains Mono, the
  wordmark and the installer slides' headlines in Sora (`fonts.display`), all from
  Debian's archive. The boot menu, the installer's welcome page and its slides show
  the name in block letters (`branding/export/`); the slides are a tour of patina in
  the landing page's dark style, with no theme artwork (October 2026). The mark is text: a summit drawn as
  contour rings with the letters of patina (i, t, n, a), the word itself as the summit
  line and the survey point ▲. `branding/logo.txt` holds it for fastfetch and the
  console, `branding/wordmark.txt` the name in block letters for `patina help` and
  the install questions, outlined in `branding/export/` for the README's header and
  the installer's welcome page; `branding/wordmark.svg` sets the mark beside patina
  for the other screens, `icon.svg` and `icon-small.svg` are the mark as large and
  small icons. The desktop's icons are Papirus as Debian ships it, its
  folders recoloured to the theme's accent and every app's icon a monochrome glyph in
  the text colour, all at one height, by the renderer; kitty is the one see-through
  window (other apps stay opaque); the start menu and the other panel popups carry a
  slight grain. The brand's colours (deep violet, violet, lavender, white, and green
  for the ▲) are aurora's and do not follow a theme; on a light ground the terminal
  prints the marks' letters black and the ▲ in aurora light's green (October 2026).
  The desktop's shape is a centred bar along the bottom edge as on Windows 11 (never
  floating: a floating bar jumps when a window is maximised), new windows
  centred at one size and the command palette in the middle of the screen; the start
  menu opens above its button (Kickoff: Plasma places its popups itself, so no KWin
  rule can centre it; Plasma's Application Dashboard, full screen and centred, is an
  option, dark over either mode), its background glass the wallpaper glows through,
  its category icons in the accent, the apps' glyphs in the bar and the menu and the
  labels in the text colour; all are knobs in `defaults/settings.yaml`. The user's
  picture is the small mark (`icon-small.svg`) while it is Debian's.
  No automatic tiling on Plasma: that would need a KWin script Debian does not package; a tiling desktop
  is the Hyprland add-on.
- Speed: the system tuning CachyOS ships as configuration (zram, I/O schedulers, memory
  sysctls, journald and systemd limits, boot) is copied as data for every install, kept
  under `defaults/system/`; its kernel, rebuilt packages and own repository are not.
  Plasma-side speed settings are curated defaults like any other.
- Install model: per user, Omarchy-style. Clone at `~/.local/share/patina`, symlink
  `~/.local/bin/patina`, state in `~/.local/state/patina/`. `PATINA_PATH` overrides.
- Updates: `git pull` plus versioned migrations (`migrations/`), then an unattended
  `patina install` of the bundles installed on the machine, so an update ends where a
  fresh install does (October 2026).
- Image: a small live image built with Debian's live-build, with Calamares as the branded
  installer. The live system carries only the installer; Plasma and the base packages
  are fetched from Debian's mirrors during the install, so the image stays under one
  gigabyte and the installed system is current. Built in GitHub Actions, booted in QEMU
  in CI, published as a GitHub release asset only after that boot test and one manual
  install check. Secure Boot through Debian's signed shim, GRUB and kernel. First boot
  runs the same `patina install` as Path A.
- Try patina for Windows: TryPatina.exe (`patina-os/win-emulator`, Go, GPL-3.0-or-later)
  sets up stock QEMU from winget on the Windows Hypervisor Platform, downloads the
  released amd64 image, checks it against `SHA256SUMS` and lets the installer put patina
  on a virtual disk, as on a PC; it carries no image of its own (October 2026). The VM is
  a device (`devices/try-patina-windows/`), detected by the product name the launcher
  gives it: spice-vdagent for copy and paste and the Plasma X11 session first, because
  spice-vdagent shares the clipboard only there.
- ARM: aarch64 is first-class from day one. An "ARM version" is a tested-hardware list
  plus device glue under `devices/`, never a separate release or branch.
- License: GPL-3.0-or-later. Theme artwork may carry its own license (`artwork_license`).
- Data format: YAML, parsed with the Go `yq` (mikefarah). Debian's `yq` package is the
  Python jq wrapper and must not be used.
- The name is final: patina. The 21 it once carried was dropped in October 2026.
  The GitHub account is `patina-os` (renamed from `patina21` in October 2026, before
  anything was shared); kortex's D-Bus name is `io.github.patina_os.kortex` since its
  0.1.2.

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
- write "Debian patina", "patina Linux" or `Patina`
- paste the logo into a script or redraw it; `branding/logo.txt` is the only copy of the
  mark, `branding/wordmark.txt` of the text wordmark and `branding/wordmark.svg` of the
  typeset one (it and `icon.svg` repeat the mark's characters, changed together with
  `logo.txt`); scripts print or copy them (`print_logo` and `print_wordmark` in
  `lib.sh`, the image build and the renderer copy the SVG). `branding/export/` holds
  `wordmark.txt` drawn as outlines (SVG, for places without its fonts) and every mark
  as PNG and JPG for places outside patina (`branding/export/README.md`), derived from
  them and drawn again when one changes

## Repository map

| Directory | Holds |
|---|---|
| `bin/` | the `patina` entry point; `bin/patina-<cmd>` per subcommand, thin bash; `lib.sh` holds the few functions they share, among them the theme loader and template filler the renderers and the image build use |
| `branding/` | the marks as data: `logo.txt` (the mark) and `wordmark.txt` (the name in block letters) are what scripts print, `wordmark.svg` (the mark typeset beside patina), `icon.svg` and `icon-small.svg` what screens show; `export/` the block-letter name as outlined SVG, and every mark as PNG and JPG up to 2048 px, shown in its README |
| `themes/` | theme packs as data; `_template/` is the skeleton |
| `defaults/` | desktop-agnostic keybindings and curated settings; `apps.yaml` the settings merged into apps' own files; `services.yaml` the services the AI agent can connect to (MCP presets); `agent.md` the AI agent's standing instruction; `system/` the system tuning files and Firefox's policies |
| `desktops/` | per-desktop renderers (templates, an `actions.yaml` for the keybindings, Plasma's `icons.yaml` for the folder colours of an icon theme, one `apply.sh`) and the headless session the desktop workflow screenshots (`screenshot.sh`); Plasma's `askpass.sh`, the AI agent's sudo password dialog; `plasma/` first; `terminal/` renders the terminal and its tools for every desktop |
| `manifest/` | bundles, backends, upstream recipes: everything that gets installed |
| `migrations/` | timestamped, idempotent update steps |
| `devices/` | the only place for device- or architecture-specific files |
| `iso/` | live-build configuration, Calamares configuration and branding, the templates `iso/live/assets.sh` renders from the theme (installer artwork, icons and stylesheet, boot menu theme, the live system's fonts, the Wi-Fi step's terminal), first-boot unit, QEMU boot test (Phase 3) |
| `docs/` | roadmap, branding and trademark rules, tested hardware, `credits.yaml` (the people and projects patina is made of: `patina credits`, the installer's last slide and the README's Credits section), the manual VM run that closes Phases 1 and 2 (`vm-run.md`); `design/` keeps design explorations as self-contained HTML pages (`futures.html`: the eight directions of the 2026 redesign, candidates for more themes); `screenshots/` holds the installer, desktop, start menu and command palette screenshots the README shows, taken by the image's boot test and by the desktop workflow's headless Plasma session, refreshed per release |
| `.github/workflows/` | lint (shellcheck, yamllint), smoke (Debian containers, x86_64 and aarch64), desktop (Path A plus a Plasma X11 session on a virtual framebuffer, screenshots), iso (build, boot test, release; an alpha tag's release has no images) |
| `.github/ISSUE_TEMPLATE/` | the test report form testers fill in after a run of `docs/vm-run.md` |

Each directory's README is the authority on its file format.

## Naming

- `patina`: always lowercase, also at the start of a sentence. Command: `patina`.
- Environment variables: `PATINA_` prefix. State and config directories: `patina`.
- Files, directories, themes, devices, bundles: lowercase kebab-case.
- Scripts in `bin/`: `patina-<cmd>`, no extension. Other scripts: `.sh`.
- Data files end in `.yaml`; GitHub workflows and issue forms keep GitHub's `.yml`; Calamares keeps its
  `.conf` and `branding.desc` names and live-build its `.list.chroot` names, because the
  tools require them. They are YAML all the same and are linted as such. The files under
  `defaults/system/` and `devices/*/system/` are the exception: sysctl, udev, systemd
  and SDDM files named by their destination (Firefox's policies are JSON), excluded from the YAML checks; so is `defaults/agent.md`, the agent's
  instruction in Markdown, which opencode reads.
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
  `defaults/system/` and the `system/` directory of a detected device (`devices/`), for the keyring and sources file of an `apt-source` recipe, and
  for the login screen's wallpaper and the Breeze SDDM theme's `theme.conf.user`
  (`/usr/local/share/patina/login.png`, written by the desktop renderer).
  The scripts drop the `sudo` when they already run as root (a container, first boot).
- Desktop configuration is written only by `desktops/<desktop>/apply.sh` (the
  terminal's by `desktops/terminal/apply.sh`), through the desktop's own tool
  (`kwriteconfig6` on Plasma) and only when a value differs, so a second run changes
  nothing. Generated files carry the theme's name and the renderer
  removes those of other themes.
- Read YAML with `yq`; never parse it with grep or sed. Write user config under XDG
  directories, never into the repository checkout.
- Short, obvious code beats clever code. A function used once is not a function.
- One data file per concern; no generated files committed. The exceptions are
  `docs/screenshots/`, images CI produces, committed as they come, never edited, and
  `branding/export/`, the marks drawn as pictures, drawn again when a mark changes.

## Data formats

- Theme: `themes/<name>/theme.yaml`, base16 palette keys, optionally `accent` and
  `accent_alt` and a block for the other mode (`light:`). See `themes/README.md`.
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
5. Validate the YAML, add a `CHANGELOG.md` line, open a pull request. A theme kept in a
   repository of its own (`patina-<name>-theme`) installs with `patina theme install
   <git-url>`, which keeps only its data (`themes/README.md`).

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
