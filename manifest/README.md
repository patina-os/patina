# manifest/

Everything patina21 installs is listed here as data. Scripts read these files; they never
contain package names themselves.

```text
manifest/
  bundles/<bundle>.yaml    what to install, by canonical name, grouped for the installer TUI
  backends/<backend>.yaml  how one package manager installs it (apt is the reference)
  upstream.yaml            tools that come from their upstream installers (agent CLIs, yq)
```

## Bundles

```yaml
name: dev
description: Shown in the TUI
default: true        # preselected in `patina install`
required: false      # true only for base: the user cannot deselect it
packages:            # canonical names, resolved through backends/<backend>.yaml
  - git
flatpaks:            # Flathub application IDs; identical on every base
  - org.kde.okular
upstream:            # keys of manifest/upstream.yaml
  - claude-code
```

Canonical names are the Debian package names, because Debian is the reference base.
A backend file maps them only where its own name differs.

## Backends

A backend is one YAML file: the `ID` values from `/etc/os-release` it serves, the commands
for refresh, install and is-installed, and the name map. Adding a base means adding a file
here (and a container for it in the smoke workflow), not editing scripts. `apt.yaml` is
the reference and the only backend CI runs; `zypper.yaml`, `dnf.yaml` and `pacman.yaml`
are kept as data for possible later bases and are untested: no container runs them until
the roadmap schedules that base. Their maps cover the packages the bundles name today;
a new bundle entry means checking the three maps too.

## Sources, in order of preference

1. the base's own repositories (security updates are the base's job)
2. Flathub, for GUI apps we do not want to track
3. upstream installers, only for tools that have no packaged version worth using: an npm
   or uv package, the upstream's install script, a single release binary, or the
   upstream's own signed apt repository for an opt-in tool

Never: snap, repositories we would have to maintain ourselves, binaries we build
ourselves, an upstream repository or installer for anything installed by default.
