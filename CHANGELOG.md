# Changelog

All notable changes to patina21 are documented here. The format follows
[Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

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
