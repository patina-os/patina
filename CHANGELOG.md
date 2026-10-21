# Changelog

All notable changes to patina21 are documented here. The format follows
[Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

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

### Added

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
