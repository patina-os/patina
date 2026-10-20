# patina21

A polish layer for KDE Plasma on openSUSE: themes, consistency across apps, curated
defaults, agent CLIs and a free-software, EU-sovereign app stack. Not a distribution.

**Status: pre-alpha.** Nothing is installable yet. See the [roadmap](docs/roadmap.md).

## What it is

patina21 takes a stock openSUSE Tumbleweed with Plasma and finishes it: one consistent
theme across Plasma, terminal and editors, sane defaults, the apps a privacy-minded
developer in the EU wants, and the agent command-line tools (Claude Code, Codex CLI,
opencode, Ollama for local models) installed the way their upstreams intend.

It is inspired by [Omarchy](https://omarchy.org): the polish, the themes, the
boot-to-finished-desktop install, and the `git pull` plus migrations update model. It does
not copy Omarchy's tiling-first UX, patched kernel or own package repository.

## What it is not

- not a fork of openSUSE and not a distribution: every package comes from openSUSE
  repositories, Flathub or an upstream installer
- not a kernel, not a package repository, not rebuilt packages: security is the base's job
- not Hyprland-first: Plasma first; Hyprland may become an add-on later
- not for Apple Silicon

## The stance

1. Free software only. No snap, no proprietary defaults, no US cloud services as defaults.
2. Own the UI, own nothing that gets CVEs.
3. Data over code: themes, keybindings and package lists are data files; scripts stay thin.
4. Every design choice must reduce the work for a one-person, part-time maintainer.

## Install

Two paths, one layer. If they ever diverge, Path A wins.

| Path | What you do | Status |
|---|---|---|
| A: on stock openSUSE | Install openSUSE Tumbleweed with Plasma, `git clone` this repository, run `patina install` (a small TUI: theme, app bundles, Nextcloud, agent CLIs) | pre-alpha, not usable yet |
| B: the patina21 ISO | Boot the ISO, answer three questions (disk, user, theme), get the finished desktop. Built from openSUSE's own tooling on the Open Build Service; it only automates Path A | pre-alpha, planned for roadmap Phase 2 |

Updates: `patina update` runs `git pull` and then any pending migrations.

## Supported bases

| Base | Architectures | Status |
|---|---|---|
| openSUSE Tumbleweed | x86_64, aarch64 | reference base, pre-alpha |
| openSUSE Leap | x86_64, aarch64 | planned second flavour |
| Fedora | | possible later, not a priority |
| Ubuntu, Arch, CachyOS | | not planned |

The layer itself has no architecture. aarch64 is a first-class target from day one; see
[docs/hardware.md](docs/hardware.md) for what has been tested.

## The app stack

Nextcloud client, Thunderbird, Element, KeePassXC, an office suite (Collabora Office or
OnlyOffice, to be decided), plus the agent CLIs above. GUI apps we do not want to track
come from Flathub; agent CLIs come from their upstream installers (npm, uv).

## FAQ

**What does the 21 stand for?** The maintainer's personal secret.

**Is this a new distribution?** No. It is a layer on openSUSE and an ISO that only
automates installing that layer. There is no patina21 kernel, package repository or
rebuilt package, and there never will be.

**Is it Omarchy for KDE?** It borrows Omarchy's polish and update model, not its tiling
UX, kernel or package repository. Themes are stored as desktop-agnostic data, so a
Hyprland rendering could be added later without touching them.

**Why openSUSE?** A community project with an EU vendor behind it, Plasma as its flagship
desktop, an official aarch64 port, and the Open Build Service to build and sign images
without running our own infrastructure.

**Why Plasma?** The most complete free desktop, openSUSE's flagship, and it already
handles the cross-app consistency (GTK, Flatpak portals) a layer would otherwise have to
build.

**Does it run on ARM?** It is meant to. Phase 1 runs the bootstrap in an aarch64 container
in CI; real hardware starts with the Raspberry Pi 4 and continues with ARM laptops as they
gain openSUSE support. There is never a separate ARM edition.

**Can I use it on Fedora or Ubuntu?** Not yet. The package manifest is base-agnostic by
design, but other backends come only after both install paths are stable on openSUSE.

## Contributing

Theme packs are the most welcome contribution: copy `themes/_template/`, fill in the
palette and wallpapers, open a pull request. `themes/README.md` has the details.
Everything else: open an issue first; this is a one-maintainer side project.

## License

GPL-3.0-or-later for everything in this repository. Theme artwork may carry its own
license, declared in each theme's `theme.yaml`.
