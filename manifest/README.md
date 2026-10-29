# manifest/

Everything patina installs is listed here as data. Scripts read these files; they never
contain package names themselves. The one exception is the Go `yq` download in
`bin/patina-install`, because `yq` cannot read its own recipe; CI checks it equals the
recipe here.

```text
manifest/
  bundles/<bundle>.yaml    what to install, by canonical name, grouped for the installer TUI
  backends/<backend>.yaml  how one package manager installs it (apt is the reference)
  upstream.yaml            tools that come from their upstream installers (agent CLIs, yq,
                           the ArtCraft Launcher)
```

## Bundles

```yaml
name: dev
description: Shown in the TUI   # no comma: gum takes the preselected lines as a list
default: true        # preselected in `patina install`
required: false      # true only for base: the user cannot deselect it
packages:            # canonical names, resolved through backends/<backend>.yaml
  - git
flatpaks:            # Flathub application IDs; identical on every base, installed per user
  - org.kde.okular
upstream:            # keys of manifest/upstream.yaml
  - claude-code
ai: local            # only on the bundles that answer the AI question (local, cloud)
```

A bundle with an `ai` key is not a line of the bundle list: it is the answer of the AI
question of `patina install` and the installer's AI page (`ai-local`, `ai-cloud`). The
question's answer adds that bundle; `--bundles ai-cloud` and `PATINA_AI=cloud` do the
same.

Canonical names are the Debian package names, because Debian is the reference base.
A backend file maps them only where its own name differs. `patina install --list`
prints the bundles; `--bundles a,b` picks them (base is always in), `--all` takes every
one.

## Backends

A backend is one YAML file: the `ID` values from `/etc/os-release` it serves, the commands
for refresh, install and is-installed, the name map, and under `system` the one command
that writes a system file (`write`, for `defaults/system/` and a detected device's `system/`, the keyrings and sources of
`apt-source` recipes, and the login screen's wallpaper and SDDM override the desktop
renderer writes) with the commands run after a tuning file changed (`apply`). Every command that needs root starts with `sudo`; the scripts drop it when
they already run as root. Adding a base means adding a file here (and a container for
it in the smoke workflow), not editing scripts. `apt.yaml` is the reference and the only
backend CI runs; `zypper.yaml`, `dnf.yaml` and `pacman.yaml` are kept as data for
possible later bases and are untested: no container runs them until the roadmap
schedules that base. Their maps cover the packages the bundles name today; a new bundle
entry means checking the three maps too.

## Upstream recipes

`upstream.yaml` documents its methods at the top. Each recipe names what it leaves
behind, so `patina install` can skip it and `patina doctor` can report it: the `command`
on PATH (binary, script), the `package` (npm, uv, apt-source), or for a `git` recipe the
`ref` it was installed at, recorded in the state directory (a new `ref` installs again).
Everything lands in the user's `~/.local` except an `apt-source` recipe, which goes
through the backend. The `git` method is for kortex, patina's own runner for KRunner: a
tagged release, installed per user by the repository's own script.

## Sources, in order of preference

1. the base's own repositories (security updates are the base's job)
2. Flathub, for GUI apps we do not want to track
3. upstream installers, only for tools that have no packaged version worth using: an npm
   or uv package, the upstream's install script, a single release binary, or the
   upstream's own signed apt repository for an opt-in tool, and for a default only when
   the software is free and neither Debian's archive nor Flathub carries it (Euro-Office
   today; it moves to Flathub as soon as Flathub carries it); an opt-in app that is free
   and that neither carries may also come from its upstream's release (the ArtCraft
   Launcher's AppImage, a `binary` recipe), until one of them carries it

Never: snap, repositories we would have to maintain ourselves, binaries we build
ourselves, an upstream repository or installer for anything Debian or Flathub carries.
