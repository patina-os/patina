# patina

```text
            █▌  ▲
 ▄▄▟▙▖ ▄█▙▖▗█▙▄▗▄▄▗▄▟█▖ ▗▟█▄
 ██▀▜█ ▀▀▜█▝█▛▀▝▜█▐█▛▜█ ▝▀▀█▌
 █▌ ▐█ ▄███ █▌  ▐█▐█ ▐█ ▗▟██▌
 █▙ ▟█▗█▌▐█ ▜▙  ▐█▐█ ▐█ ▟█ █▌
 █▛██▛ ██▛█ ▝██ ▐█▐█ ▐█ ▐██▜▌
 █▌
 ▀▘
⢄⣀⡀   ⢀⣀⡠⠤⠤⠒⠒⠒⠒⠢⠤⢄⣀⣀   ⢀⣀⣀⠤⠤⠒
  ⠈⢉⣉⡩⠥⠔⠒⠒⠒⠒⠤⠤⣀⡀    ⠉⣉⣉⠥⠔⠒⠒⠒⠒
```

Themes, consistency across apps, curated defaults, agent CLIs and a free-software,
EU-sovereign app stack on top of Debian stable with Plasma. Not a distribution.

**Status: pre-alpha.** `patina install` installs the app stack and the system tuning on
Debian 13 and renders the default theme, aurora, into Plasma's configuration (checked in
CI containers on x86_64 and aarch64, not yet on a real desktop); the branded install is
still to come. See the [roadmap](docs/roadmap.md).

## Screenshots

The installer's welcome page, as the live image's boot test captures it in CI (amd64,
QEMU, Calamares as Debian 13 ships it, branded through data):

![The patina installer's welcome page](docs/screenshots/installer-amd64.png)

The finished desktop, as the `desktop` workflow captures it in CI (amd64, a Plasma X11
session on a virtual framebuffer after `patina install`): the centred bar and kitty with
the fastfetch greeting, in aurora, the default theme.

![The patina desktop with the aurora theme](docs/screenshots/desktop-amd64.png)

The screenshots are taken by CI, never edited; see `iso/README.md`.

## What it is

patina takes a stock Debian with Plasma and finishes it: one consistent theme across
Plasma, terminal and editors, sane defaults, the apps a privacy-minded developer in the
EU wants, and the agent tools (Claude Code, Codex CLI, opencode, Claude Desktop, Ollama
for local models) installed the way their upstreams intend.

It is inspired by [Omarchy](https://omarchy.org): the polish, the themes, the quick
branded boot-to-finished-desktop install, and the `git pull` plus migrations update
model. It does not copy Omarchy's tiling-first UX, patched kernel or own package
repository.

## What it is not

- not a fork of Debian and not a distribution: every package comes from Debian's
  archive, Flathub or an upstream installer
- not a kernel, not a package repository, not rebuilt packages: security is the base's job
- not Hyprland-first: Plasma first; Hyprland may become an add-on later
- not for Apple Silicon

## The stance

1. Free software only. No snap, no proprietary defaults, no US cloud services as defaults.
   Proprietary agent tools exist as an opt-in bundle, never preselected.
2. Own the UI, own nothing that gets CVEs.
3. Data over code: themes, keybindings and package lists are data files; scripts stay thin.
4. Every design choice must reduce the work for a one-person, part-time maintainer.

## Install

Two paths, one layer. If they ever diverge, Path A wins.

| Path | What you do | Status |
|---|---|---|
| A: on stock Debian | Install Debian 13 with Plasma, `git clone` this repository, run `patina install` (it asks the theme and the app bundles on a terminal; flags or `--unattended` skip the questions) | pre-alpha: installs the app stack, the system tuning and the theme, checked in CI containers, not yet on a real desktop |
| B: the patina image | Boot a small live image, answer the installer (disk, user, locale), get the finished desktop. Plasma and the base are downloaded from Debian's mirrors during the install; first boot runs Path A | pre-alpha: the image builds and boots to the installer in CI (x86_64 and aarch64), not released yet; the first boot waits for Path A |

```sh
sudo apt install git curl
git clone https://github.com/patina21/patina.git ~/.local/share/patina
~/.local/share/patina/bin/patina install            # the default bundles: base, desktop
~/.local/share/patina/bin/patina install --all      # plus the opt-in agent tools
```

`patina install --list` shows the bundles, `patina doctor` checks the result,
`patina theme list` and `patina theme set <name>` switch the theme (`PATINA_THEME=<name>`
picks one for the install), and `patina update` runs `git pull` and then any pending
migrations. Put `~/.local/bin` on
your PATH and link `patina` there (`ln -s ~/.local/share/patina/bin/patina
~/.local/bin/patina`).

## Supported bases

| Base | Architectures | Status |
|---|---|---|
| Debian 13 (trixie) | x86_64, aarch64 | reference base, pre-alpha |
| Debian 14 | x86_64, aarch64 | follows when it becomes stable |
| openSUSE Tumbleweed | | possible later; backend file kept, untested |
| Fedora | | possible later, not a priority; backend file kept, untested |
| Arch Linux | | possible later, not a priority; backend file kept, untested |
| Ubuntu, CachyOS | | not planned |

The layer itself has no architecture. aarch64 is a first-class target from day one; see
[docs/hardware.md](docs/hardware.md) for what has been tested.

## The look

One theme from the boot menu to the desktop, from one data file: the live image's boot
menu, the installer, the login screen, the Plasma splash, Plasma itself, Konsole, kitty,
GTK and Flatpak apps, the install questions, the terminal greeting and the tools in the
terminal (btop, neovim, bat, fzf, lazygit, eza, starship) all take their colours from
the theme's palette; the words are set in Source Sans 3, the details in
JetBrains Mono, the wordmark in Sora. The default theme is aurora, made for OLED
screens: true black, neon green as the accent and violet as the second colour, with a
contour map that glows green at its summit and turns violet towards the edges. It is
dark by default; `patina theme mode light` switches it to its light palette and
`patina theme mode dark` back. The mark is text, a summit shaded with the letters of
patina in violet with a green survey point, so the terminal and the screens show the
same one. datum (graphite, ice and coral around a contour map) and amethyst, the first
theme, a purple palette with two abstract wallpapers, stay as options (`patina theme
set datum`).
Meta plus
one key opens the terminal (Return), the search (Space), the browser (B), the files (E)
and, with the agent tools installed, the agent CLI in its own terminal profile (A);
Meta+K shows all of them, and Plasma's own, at a glance (`patina keys`). Themes shared
in a repository of their own install with `patina theme install <git-url>`, as data
only. The
Plasma-side speed settings CachyOS is known for (lowest compositor latency, shorter
animations, file-name-only indexing, the Wayland session) are curated defaults. So is the
shape of the desktop: one bar with the launcher and the task icons in the centre, as on
Windows 11, and new windows that open centred at the same size. The first `patina
install` and every fresh login get the bar; after that your panels are yours, and
`patina theme set <name> --layout` brings the bar back.

## The app stack

Nextcloud client, Thunderbird, Element, KeePassXC, Euro-Office (the European, AGPL fork of
ONLYOFFICE), kitty as the terminal, a developer kit (fish, starship, bat, eza, fzf,
ripgrep, lazygit, btop, zoxide, atuin, git-delta, neovim, fastfetch) and the Zed editor,
plus the agent tools above. Everything comes from Debian's archive except what it does
not carry: GUI apps we do not want to track come from Flathub, agent tools from their
upstream installers (npm, uv, Anthropic's own apt repository for Claude Desktop), and
Euro-Office from Nextcloud's signed apt repository until Flathub carries it. Ollama is
the local backend the agent tools point at.

## FAQ

**Is this a new distribution?** No. It is a layer on Debian and a live image that only
automates installing that layer. There is no patina kernel, package repository or
rebuilt package, and there never will be.

**Is it Omarchy for KDE?** It borrows Omarchy's polish, quick branded install and update
model, not its tiling UX, kernel or package repository. Themes are stored as
desktop-agnostic data, so a Hyprland rendering could be added later without touching them.

**Why Debian?** The strictest free-software archive of the large bases, the broadest
arm64 support, a two-year stable cycle that keeps maintenance low, and the ecosystem:
third-party installers, vendor packages and manuals assume apt. Debian 13 ships Plasma 6.

**Wasn't this on openSUSE?** It started there, and switched before anything shipped.
openSUSE has the better Plasma polish and the Open Build Service; Debian has the
ecosystem users actually meet. The package manifest is base-agnostic, so the openSUSE
backend stays as data for a possible later flavour.

**Is it fast like CachyOS?** It copies what makes CachyOS feel fast and is configuration:
zram, I/O schedulers, memory and systemd settings, a lean boot, low-latency Plasma
defaults. It does not copy the custom kernel or the rebuilt packages, because patina
owns nothing that gets CVEs.

**Why Plasma?** The most complete free desktop, and it already handles the cross-app
consistency (GTK, Flatpak portals) a layer would otherwise have to build.

**Does it run on ARM?** It is meant to. Phase 1 runs the bootstrap in an aarch64 container
in CI; real hardware starts with the Raspberry Pi 4 and continues with ARM laptops as they
gain Debian kernel support. There is never a separate ARM edition.

**Can I use it on Fedora or openSUSE?** Not yet. The package manifest is base-agnostic by
design, but other backends come only after both install paths are stable on Debian.

## Contributing

Theme packs are the most welcome contribution: copy `themes/_template/`, fill in the
palette and wallpapers, open a pull request. `themes/README.md` has the details.
Everything else: open an issue first; this is a one-maintainer side project.

## License

GPL-3.0-or-later for everything in this repository. Theme artwork may carry its own
license, declared in each theme's `theme.yaml`.
