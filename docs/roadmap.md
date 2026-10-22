# Roadmap

patina21 ships in phases. Each phase ends with something a user can run, and nothing in a
later phase may break an earlier one. Path A (stock Debian plus `patina install`) is the
reference path and must work at every point. The numbers give the order the phases are
finished in, not the order they were prepared in: the image and the device entries were
written as data before the layer's own commands existed, so Phases 3 and 4 already carry
ticked items while Phase 1 is open.

Status: pre-alpha. The core commands exist and the smoke test runs `patina install`
twice in Debian 13 containers on both architectures; the live image builds and boots to
the installer in CI; the Plasma renderer and the first theme, amethyst, render from data
and switch without leftovers in the same containers. Phase 1's last step, the run on a
fresh Debian 13 VM with Plasma, is open; Phase 2 waits for the same run to see the
theme on a real desktop; Phase 3 is open.

Settled on this roadmap: the TUI helper is `gum` (Debian 13 ships 0.14 on both
architectures); the office suite is Euro-Office; the terminal is kitty until Debian
carries Ghostty; the developer tools are part of the default desktop bundle (all
Phase 1); the first theme is purple with generated artwork (Phase 2); the agent tools
integrate through a shortcut, a terminal profile and Ollama as the local backend
(Phases 1 and 2); the system tuning CachyOS ships as configuration is copied as data for
every install, its kernel and rebuilt packages are not (Phases 1 and 2); the first theme
is called amethyst and the agent shortcut opens opencode, the free one, by default
(Phase 2); the fonts are Inter and JetBrains Mono, and the installer, the boot menu, the
login screen and the splash share the theme's look, rendered from its palette (Phase 3).

## Phase 1: the core commands on x86_64 (Debian 13)

`patina install` without a TUI yet: it installs what the manifest says, through the apt
backend, Flathub and the upstream recipes, plus the commands around it. The code is in;
what the ticks below still owe is the "done when" run on a real VM.

- [x] `patina install`: the `base` and `desktop` bundles, the Flathub remote and the
  flatpaks, the upstream recipes (npm, uv, the Go `yq` release binary); bundles chosen
  by flags, no prompts; honours `PATINA_UNATTENDED=1` (defaults for everything).
  Flatpaks are installed per user, like the layer itself; nothing needs sudo except the
  backend's commands
- [x] the extended desktop bundle, from Debian 13's archive on both architectures:
  kitty as the terminal (Ghostty is in neither Debian's archive nor Flathub; it takes
  kitty's place in Phase 6 if Debian 14 carries it) and the developer tools fish,
  starship, bat, eza, fzf, ripgrep, lazygit, btop, zoxide, atuin, git-delta, neovim and
  fastfetch; the Zed editor from Flathub (`dev.zed.Zed`, free licences, listing not
  verified by its publisher) with its telemetry and AI off through `defaults/apps.yaml`. Not in
  Debian 13 and therefore not shipped: helix, yazi, zellij, difftastic, wezterm
- [x] the opt-in `agents` bundle: Claude Code, Codex CLI, opencode and Ollama from their
  upstream installers, Claude Desktop from Anthropic's signed apt repository. Ollama is
  the local backend: its installer sets up the service, `patina install` points
  opencode at `localhost:11434`, and the office suite too if Euro-Office kept
  ONLYOFFICE's AI plugin (to verify), so documents never leave the machine
- [x] the office suite: Euro-Office, the AGPL-3.0 fork of ONLYOFFICE by a European
  consortium (IONOS, Nextcloud, XWiki, OpenProject and others; first stable release
  June 2026), desktop editors for amd64 and arm64. Debian does not package it and
  Flathub does not carry it yet (an upstream issue is open), so it comes from
  Nextcloud's signed apt repository, where the signed builds are published as Nextcloud
  Office (package `nextcloud-office-nextcloudoffice`): an `apt-source` recipe in
  `manifest/upstream.yaml`, moved to Flathub as soon as Flathub carries it. This is the
  one default that comes from an upstream apt repository; the rule in `manifest/` says
  when that is allowed
- [x] the system tuning, in the `base` bundle for every install, after what CachyOS
  ships as configuration (its `cachyos-settings` package, GPL-3.0): zram with zstd
  through `systemd-zram-generator`, I/O scheduler udev rules (bfq for disks,
  mq-deadline for SATA SSDs, none for NVMe), the memory sysctls for zram, a journald
  size cap, shorter systemd stop timeouts, THP defrag, `irqbalance`, `systemd-oomd`, a
  `MODULES=dep` initramfs and a one-second GRUB timeout. The files live as data under
  `defaults/system/` and are written through the apt backend's one sudo path, the only
  place the layer touches `/etc`; `patina doctor` reports them. Not copied: the kernel,
  the rebuilt packages, the disabled NMI watchdog and relaxed pointer restrictions, the
  US NTP servers, the Nvidia options
- [x] `patina update` (git pull plus pending migrations), `patina migrate`,
  `patina doctor` (base and architecture, `yq`, missing packages, state directory)
- [x] verified package names: the "illustrative" notes in `manifest/` go away
- [x] CI: the smoke job runs `patina install` unattended, twice, in the Debian 13
  containers on x86_64 and aarch64 (the ARM plan's first step happens here)
- [ ] the run that closes the phase: a fresh Debian 13 VM with Plasma, `git clone`,
  `patina install`, a second run, `patina doctor`; what it shows missing goes back into
  the data. The CI containers prove everything but the systemd side (zram, oomd, the
  schedulers, GRUB and the initramfs) and the sudo path as a user
- Done when: a fresh Debian 13 VM with Plasma gets the whole app stack with one command,
  a second run changes nothing, and `patina doctor` reports clean.

## Phase 2: theming (the Plasma renderer and the first theme)

The code and the data are in; what the ticks still owe, like Phase 1's, is the look on a
real Plasma desktop, which the same VM run gives.

- [x] `desktops/plasma/apply.sh` and its templates, against Plasma 6.3 as Debian 13
  ships it: colour scheme, Konsole and kitty profiles, GTK and Qt consistency,
  wallpaper, keybindings from `defaults/keybindings.yaml`, settings from
  `defaults/settings.yaml`. A generated look-and-feel package hands a fresh session
  (the image's first login) the whole theme at once
- [x] the first theme under `themes/`, amethyst, and `defaults/settings.yaml` pointing
  at it: a purple signature palette that continues the logo's pink-to-purple gradient,
  and two wallpapers kept as SVG in the theme and rendered at apply time, abstract
  organic forms with Google DeepMind's visualisations on Pexels as the reference style,
  never their files; the artwork is CC-BY-SA-4.0 and the theme data GPL-3.0-or-later
- [x] the agent shortcut: the `agent` action in `defaults/keybindings.yaml` (Meta+A)
  opens the agent CLI of `defaults/settings.yaml` (opencode by default) in a dedicated
  kitty profile the renderer writes from the palette; the action is skipped when the
  `agents` bundle is not installed
- [x] `patina theme list|set|current`; `patina install` applies the default theme and
  honours `PATINA_THEME=<name>`
- [x] curated keybindings and settings: the placeholders in `defaults/` became the real
  defaults, including the Plasma-side speed settings: KWin's lowest-latency policy, a
  halved animation factor, Baloo limited to file names under home, the Wayland session
  as the login screen's default (`defaults/system/sddm.conf.d/`), and no autostart
  entries beyond Plasma's own
- [x] the desktop's shape as data: a centred bar with the launcher and the task icons in
  the middle (as on Windows 11) through the look-and-feel package's layout script, so a
  fresh login starts with it and `patina theme set --layout` gives it to an existing
  desktop; new windows centred at one share of the screen through KWin's placement and
  one window rule. No automatic tiling: Plasma has none and a KWin script from the
  store is code we would maintain; the tiling desktop is Phase 7
- [x] CI: the smoke test checks the rendered files and settings, that setting the theme
  again changes nothing, and that a copy of the theme under another name renders and
  switches back without leftovers
- [ ] the run that closes the phase: the theme on a real Plasma desktop, the live
  reload inside a session and the wallpaper through the look-and-feel package at a
  first login; what looks wrong goes back into the data
- Done when: one theme renders the whole desktop from data, `patina theme set` switches
  and switches back without leftovers, and a theme pack made by copying
  `themes/_template` renders without a code change.

## Phase 3: the branded install (TUI, first boot, the live image)

- [x] the `patina install` TUI with `gum`: on a terminal it asks the theme and the app
  bundles (the agent tools among them), shows a summary and waits for a yes; Nextcloud
  is part of the desktop bundle. The unattended mode from Phase 1 stays the contract
  the image's first boot uses
- [x] one look from the boot menu to the desktop, every colour from the default theme's
  palette: the live image's GRUB menu (theme and splash), the installer (a stylesheet
  down to the partition page, the wordmark, a veiled wallpaper, three still slides), the
  login screen (the theme's wallpaper through the backend's sudo path, Inter), the
  Plasma splash (the wordmark and one accent line), the install TUI and the fastfetch
  greeting. Inter and JetBrains Mono are the layer's fonts; the typeset wordmark
  patina²¹ is the mark of screens, the ASCII mark the mark of terminals
- [x] live-build configuration: a small live system that carries only Calamares, the
  network stack and firmware; Plasma and the base bundle are fetched from Debian's
  mirrors during the install
- [x] Calamares configuration and branding as data: disk, user, locale and keyboard
  pages; first boot asks the theme
- [x] first-boot unit and script that run the same `patina install` as Path A
- [x] the `iso` workflow: native builds on GitHub's x86_64 and aarch64 runners, boot
  test in QEMU, upload to the GitHub release of a tag only when both boot tests passed
- [x] both images build and pass the boot test in CI (amd64 under KVM, arm64 under
  emulation), on every pull request that touches the image
- [x] branding within Debian's trademark policy (`docs/branding.md`, the logo)
- [ ] one manual install in a VM per release, until Calamares can be driven unattended
  (upstream has no unattended mode; see `iso/README.md`): boot, answer the installer,
  first boot ends in `patina21 firstboot: done`
- Done when: boot, answer the installer, finished desktop identical to Path A, in a VM
  on both architectures.

## Phase 4: ARM hardware

Per-device data under `devices/`, only once a device boots Debian's kernel. Each one has
a row in `docs/hardware.md`. Apple Silicon is out of scope (Fedora Asahi, not Debian).

- [x] `devices/raspberry-pi-4/`: data only, status untested, with the manual validation
  procedure (Debian's official Raspberry Pi image, USB SSD, clean reimage per run)
- [ ] Path A on a Raspberry Pi 4; the goal is correctness, not UX. Needs Phase 1 and
  the hardware
- [x] `devices/snapdragon-x-elite/`: data only, status untested. Debian 13 runs on these
  laptops from the kernel and firmware in `trixie-backports`, installed by hand (the
  Debian wiki documents the ThinkPad T14s Gen 6); the live image cannot boot them,
  because the boot loader has to pass the model's device tree. Debian's firmware
  package covers two Lenovo models; the rest need firmware from their Windows partition
- [ ] one run of Path A on a Snapdragon X Elite laptop (the procedure is in that
  directory's README). Needs Phase 1 and the hardware. The firmware helper for the
  models Debian's archive does not cover is written after that run, from what it shows
  missing
- [ ] Snapdragon X2 Elite: waiting for upstream. Device trees land in Linux 7.4, GPU and
  NPU drivers are still upstreaming, Debian 13's kernel is 6.12; Qualcomm announced
  Debian support for late 2026. No device directory until one boots Debian's kernel
- [ ] Nvidia RTX Spark laptops (N1X): waiting for upstream. On sale since October 2026,
  Windows only, no Linux commitment from Nvidia. Community bring-ups run on patched 7.x
  kernels with Nvidia's open driver; the platform patches are not upstream, Debian 13's
  kernel is 6.12. No device directory until one boots Debian's kernel
- Done when: Path A passes on the Pi 4 and on one Snapdragon X Elite laptop with
  Debian's own kernel.

## Phase 5: the 0.1 release

- [ ] `CHANGELOG.md`: the Unreleased section becomes 0.1.0
- [ ] tag `v0.1.0`; the `iso` workflow attaches both images to the release after the
  boot tests
- [ ] the manual install check from Phase 3 on the released images
- [ ] `patina update` from 0.1.0 to the next tag works, including at least one
  migration under `migrations/`
- [ ] `docs/hardware.md`: at least one row at `works-with-caveats` or better per
  architecture
- [ ] README: the status lines and the install table say what works
- Done when: a user who reads only the README gets from the release page to a finished
  desktop on either path.

## Phase 6: Debian 14

When Debian 14 becomes stable (expected in 2027). The same layer; what changes is data.
Path A keeps working on Debian 13 for as long as Debian supports it; the image moves to
Debian 14.

- [ ] the distribution name in `iso/live/auto/config`, the `debian:13` container tags
  in the `smoke` and `iso` workflows, the firmware list of the live image
- [ ] the Plasma version the renderer targets
- [ ] a migration only if Plasma's configuration moved
- [ ] Ghostty takes kitty's place as the terminal if Debian 14 carries it (Ubuntu 26.04
  packages it, Debian's archive does not today); kitty stays otherwise
- Done when: both paths pass on Debian 14 and the release images are built from it.

## Phase 7: the Hyprland add-on

Needs Phase 6: Debian 14 carries Hyprland in its main archive, Debian 13 only in
`trixie-backports`, and the manifest installs from the main archive only. Never the
default. The contract is in `desktops/hyprland/README.md`.

- [ ] `desktops/hyprland/apply.sh` and its templates, from the same theme data as the
  Plasma renderer: window colours, Waybar and Fuzzel styles, `foot` colours,
  wallpaper, keybindings rendered to `bind` lines
- [ ] a `hyprland` bundle; `patina install` offers the desktop; the smoke test resolves
  its packages
- Done when: the first theme renders on Plasma and on Hyprland from the same data,
  switching desktops keeps the theme, and `desktops/plasma/` is untouched.

## Later, unscheduled

- zypper (openSUSE), dnf (Fedora) and pacman (Arch) backends: kept as untested data under
  `manifest/backends/`, with the name maps for today's bundles. A smoke container and a
  README row with a status come only after Phase 5, one base at a time
- more themes and more devices, as contributors bring them and as devices boot Debian's
  kernel; neither needs a phase

## Non-goals

Own kernel, own package repository, rebuilt packages, own binaries, proprietary or
US-cloud defaults, snap, Hyprland-first UX, Apple Silicon, supporting bases other than
Debian before Path A and Path B are stable, a separate "ARM edition".
