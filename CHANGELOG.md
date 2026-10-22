# Changelog

All notable changes to patina21 are documented here. The format follows
[Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- The datum theme, the new default: graphite, the ice blue of contour lines and one
  coral accent (`base0E`), with a contour map around a survey point as its wallpaper,
  drawn once and kept as SVG artwork (CC-BY-SA-4.0). amethyst stays as an option.
- `docs/design/futures.html`: the eight directions of the October 2026 redesign
  (Perigee, Sodium, Phosphor, Nacre, Sirocco, Canopy, Cascade, Datum) with mockups,
  palettes, type and what each would cost to ship, kept as candidates for more themes.
- A migration for installed machines: `patina update` runs `patina install` once more,
  which installs the new fonts and renders the theme already set again.
- The image's boot test takes a screenshot of the installer screen through QEMU's
  monitor and the `iso` workflow uploads it with the serial log. The README shows the
  amd64 one from `docs/screenshots/`.
- The `desktop` workflow takes a screenshot of the finished desktop: `patina install`
  as a user in a Debian 13 container with Plasma, then `desktops/plasma/screenshot.sh`
  runs a Plasma X11 session on a virtual framebuffer (Xvfb, software OpenGL), applies
  the theme inside it, opens kitty with the fastfetch greeting and grabs the screen.
  It runs on pull requests that change the look and by hand; the README shows its amd64
  picture from `docs/screenshots/`.

### Changed

- The brand is redesigned. The mark is text: a summit drawn as contour rings and shaded
  with the letters of patina, the word as the summit line and the survey point ▲ in
  coral (`branding/logo.txt`, now UTF-8 for that one character). `patina help` and the
  fastfetch greeting print it in the brand's colours instead of the pink-to-purple
  gradient. `branding/wordmark.svg` sets the same characters beside patina²¹ in Sora
  ExtraBold; `branding/icon.svg`, the summit as dots, replaces `wave.svg` as the square
  mark.
- The interface font is Source Sans 3 instead of Inter (`fonts-adobe-sourcesans3`), in
  Plasma, GTK, the login screen, the installer and its window manager; the wordmark
  needs Sora (`fonts-sora`). Both join the desktop bundle, the live image and the
  packages the installer adds. The bar floats by default (`panel.floating: true`).
- The smoke test finds the default theme's wallpaper by name instead of expecting
  amethyst's, and the lint check for copies of the mark leaves `docs/design/` alone.
- The roadmap is renumbered into seven phases in the order they are finished: core
  commands, theming, the branded install (TUI, first boot, image), ARM hardware, the 0.1
  release, Debian 14, the Hyprland add-on. Two open decisions are settled: the TUI helper
  is `gum`, the office suite is Euro-Office, from Nextcloud's signed apt repository until
  Flathub carries it. Every file that cites a phase number follows.
- The desktop bundle grows by kitty (Ghostty once Debian carries it), the developer
  tools fish, starship, bat, eza, fzf, ripgrep, lazygit, btop, zoxide, atuin, git-delta,
  neovim and fastfetch from Debian's archive, and Zed from Flathub. The roadmap settles
  the first theme as purple with generated artwork, and the agent tools' desktop
  integration as a shortcut, a terminal profile and Ollama as the local backend.
- The system tuning CachyOS ships as configuration (zram, I/O schedulers, memory
  sysctls, journald and systemd limits, a lean boot) is adopted as data for every
  install, and the Plasma-side speed settings become curated defaults (roadmap, Phases 1
  and 2). The base bundle names `systemd-zram-generator` and `irqbalance`.
- The logo wordmark is redrawn in a bold block letterform; the patina wave is kept and the
  tagline is dropped. Still plain 7-bit ASCII within 60 columns, so it renders on a
  serial console and in a GitHub README. `branding/logo.txt` stays the only copy; the
  README headers follow it. `patina help` prints the mark with a pink-to-purple
  gradient on an interactive terminal (24-bit colour, honouring `NO_COLOR`); the file
  itself stays colourless so `/etc/issue.d`, serial consoles and the README are clean.
- The base is Debian stable (Debian 13 today) instead of openSUSE Tumbleweed, decided
  before anything shipped: third-party installers, vendor packages and manuals assume
  apt, and Debian serves the project's top priorities at least as well. Canonical
  package names are now Debian's; `manifest/backends/apt.yaml` is the reference
  backend, `zypper.yaml` stays as untested data. README, CLAUDE.md, roadmap, branding
  and hardware notes, the logo tagline and every README follow.
- The image is a small live image built with Debian's live-build, installed by
  Calamares with patina21 branding; Plasma and the base bundle are fetched from Debian's
  mirrors during the install. It replaces the KIWI description, Agama profile and Open
  Build Service plan under `iso/`. Built and boot-tested by the new `iso` workflow,
  attached to a tag's GitHub release only when the boot test passed.
- CI runs the smoke test in Debian 13 containers and resolves every package the
  manifest and the image name against Debian's archive with an apt dry run.
- The Nvidia N1X row in `docs/hardware.md` and the roadmap now carries the retail name,
  RTX Spark: the laptops are on sale since October 2026, Windows only, and wait for the
  platform patches to reach Debian's kernel.

### Added

- One look from the boot menu to the desktop (roadmap, Phase 3). Every surface before
  the desktop takes its colours from the default theme's palette, rendered at build or
  apply time, never typed by hand: the live image's GRUB menu (a theme and a splash
  live-build takes over its stock files), the Calamares installer (a Qt stylesheet for
  every page down to the partition editor, the wordmark on the welcome page, the wave in
  the sidebar, the theme's wallpaper veiled behind every page, three still slides while
  it installs, an openbox theme for its dialogs), the SDDM login screen (the theme's
  first wallpaper, written to `/usr/local/share/patina21/login.png` with the Breeze
  theme's override through the backend's one sudo path; Breeze with Inter and the
  theme's cursor from `defaults/system/sddm.conf.d/`), the Plasma splash (the wordmark
  and one accent line, `templates/splash.qml` in the look-and-feel package) and the
  fastfetch greeting of a new terminal (the ASCII mark in its gradient). The templates
  live under `iso/live/templates/` and `desktops/plasma/templates/`, filled by the
  theme loader and template filler now shared in `bin/lib.sh`; `iso/live/assets.sh`
  renders the image's files, and the smoke test runs it and checks them.
- The typeset wordmark, patina²¹ in Inter with the wave under it (`branding/wordmark.svg`,
  and `wave.svg` for a square icon), the mark of every screen; the ASCII mark in
  `branding/logo.txt` stays the mark of every terminal surface. Inter and JetBrains Mono
  become the layer's fonts (`defaults/settings.yaml`), from Debian's archive through the
  desktop bundle, the installer's package list and the live image.
- The `patina install` questions (roadmap, Phase 3): on a terminal, without `--bundles`
  or `--all`, the install asks the theme and the app bundles with `gum` (in the base
  bundle), shows a summary and waits for a yes, then prints a section line before each
  part while apt's and flatpak's own output stays visible. `--unattended`, the
  first-boot contract and CI take the same path as before.
- Theming (roadmap, Phase 2). `desktops/plasma/apply.sh` renders a theme and
  `defaults/` into Plasma's configuration for the user: a colour scheme with the
  theme's accent, Konsole and kitty profiles, wallpapers as Plasma wallpaper packages
  (SVG rendered at 3840x2160 with `rsvg-convert`, hence `librsvg2-bin` in the base
  bundle), a look-and-feel package so a fresh login starts in the theme, GTK and
  Flatpak consistency, the global shortcuts from `defaults/keybindings.yaml` through
  `desktops/plasma/actions.yaml`, the speed settings and fonts from
  `defaults/settings.yaml`; inside a session it applies live. `patina theme
  list|set|current` switches themes and back without leftovers; `patina install`
  applies the default theme or `PATINA_THEME=<name>`; `patina doctor` reports it.
- `themes/amethyst`: the first theme. A purple palette on a deep aubergine background
  that continues the logo's pink-to-purple gradient, and two abstract wallpapers drawn as
  SVG (`drift`, `bloom`), CC-BY-SA-4.0.
- The curated defaults: Meta plus one key for terminal, search, browser, files, close,
  overview and lock, Print for screenshots, Meta+A for the agent CLI in its own kitty
  profile (opencode by default, only with the agents bundle); half-length animations,
  KWin's lowest-latency policy, Baloo on file names under home only, and the Wayland
  session as the login screen's default (`defaults/system/sddm.conf.d/`).
- The desktop's shape as data (`defaults/settings.yaml`, `windows` and `panel`): a
  centred bar with the launcher and the task icons in the middle as on Windows 11, the
  files, browser and terminal pinned, written as the look-and-feel package's layout
  script so a fresh login starts with it; the first `patina install` inside a session
  applies it, and `patina theme set <name> --layout` brings it back later. New windows open centred, and a KWin rule gives
  every new main window 70% of the screen at its first appearance.
- The smoke test checks the rendered theme, that setting it again changes nothing, and
  that a copy of the theme pack renders and switches back cleanly.
- The core commands (roadmap, Phase 1). `patina install` installs the chosen bundles
  (`--bundles`, `--all`, `--list`; `--unattended` or `PATINA_UNATTENDED=1` for the
  first-boot contract): Debian packages through the apt backend, flatpaks per user from
  Flathub, the upstream recipes (the Go `yq` binary, npm and uv tools, install scripts,
  signed upstream apt repositories in deb822 form), the system tuning files from
  `defaults/system/` and the app settings from `defaults/apps.yaml`. It fetches `yq`
  itself, drops `sudo` when already root, runs twice without changes and records the
  install under `~/.local/state/patina21/`. `patina doctor` reports the base, the tools,
  missing packages, flatpaks and upstream tools, the tuning files and pending migrations;
  `patina migrate` runs pending migrations, `patina update` pulls and then migrates.
- Euro-Office joins the desktop bundle, from Nextcloud's signed apt repository (the
  signed builds are published as Nextcloud Office, amd64 and arm64). Claude Desktop's
  recipe is verified against Anthropic's repository. Every upstream recipe names the
  command or package it leaves behind.
- `defaults/system/`: the tuning after CachyOS's configuration, as the files `patina
  install` writes under `/etc`: zram with zstd, I/O schedulers per device type, the
  memory sysctls, a journald cap, shorter stop timeouts, systemd-oomd, background THP
  defragmentation, a one-second GRUB menu, a `MODULES=dep` initramfs. The base bundle
  names `systemd-oomd`, which Debian packages apart from systemd.
- `defaults/apps.yaml`: Zed with telemetry and AI off, opencode pointed at Ollama on
  this machine.
- The smoke workflow runs `patina install` unattended, twice, then `patina doctor`, in
  the Debian 13 containers on both architectures.
- `devices/snapdragon-x-elite/`: the first ARM laptop entry (roadmap, Phase 4), data
  only and untested: the models with their device trees, the firmware packages from
  Debian's archive, and the manual validation procedure after the Debian wiki. The
  Snapdragon X2 Elite and Nvidia N1X rows in `docs/hardware.md` record why they wait.
  The smoke test now resolves the packages devices name against Debian's archive too.
- `manifest/backends/dnf.yaml` and `pacman.yaml`: Fedora and Arch backends as untested
  data next to the openSUSE one, with the name maps for today's bundles (roadmap,
  "Later").
- `desktops/hyprland/README.md`: the contract for the Hyprland add-on, and why it waits
  for Debian 14 (Debian 13 carries Hyprland only in backports).
- The roadmap's "Later" section says what a Debian 14 move touches.
- The first images: the amd64 and arm64 live images build with live-build and
  Calamares 3.3 as Debian 13 ships them and boot to the installer screen in QEMU
  (roadmap, Phase 2 and 3). The `iso` workflow builds both natively, on GitHub's x86_64
  and aarch64 runners, boot-tests both and runs on every pull request that touches the
  image. The boot test falls back to CPU emulation where a runner has no KVM.
- `devices/raspberry-pi-4/`: the first device entry (status untested, data only) with
  the manual validation procedure for Path A on a Raspberry Pi 4.
- `manifest/bundles/agents.yaml`: the agent tools as an opt-in bundle (Claude Code,
  Codex CLI, opencode, Claude Desktop, Ollama). Claude Desktop comes from Anthropic's
  own signed apt repository, the only form it ships for Linux.
- Upstream recipes for the Go `yq` (Debian packages the Python one) and `uv`.

### Removed

- The openSUSE ISO scaffold (`iso/agama/`, `iso/kiwi/`, the OBS-based `iso-test`
  workflow and the Agama install test).

- The patina21 logo: an ASCII wordmark in `branding/logo.txt`, shown by `patina help`,
  in the README, on the ISO console and at first boot.
- Image scaffold under `iso/` (roadmap, Phase 2): first-boot unit and script that run
  Path A, and the live image configuration. Nothing is built yet.
- Repository skeleton: `bin/`, `themes/`, `defaults/`, `desktops/`, `manifest/`,
  `migrations/`, `devices/`, `iso/`, `docs/`, each with a README that fixes its purpose
  and file format.
- `patina` entry point with `help` and `version`; every other command reports that it is
  planned.
- Project documentation: README, CLAUDE.md, roadmap, branding and hardware notes.
- CI: shellcheck and yamllint; smoke run in containers of the base on x86_64 and
  aarch64.

[Unreleased]: https://github.com/patina21/patina21/commits/main
