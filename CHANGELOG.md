# Changelog

All notable changes to patina21 are documented here. The format follows
[Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- The patina21 logo: an ASCII wordmark in `branding/logo.txt`, shown by `patina help`,
  in the README, on the ISO console and at first boot.
- ISO scaffold under `iso/` (roadmap, Phase 2): Agama preset profile and product
  definition, KIWI description with its live-system overlay, first-boot unit and
  script that run Path A, QEMU install test and the `iso-test` workflow. Nothing is
  built yet.
- Repository skeleton: `bin/`, `themes/`, `defaults/`, `desktops/`, `manifest/`,
  `migrations/`, `devices/`, `iso/`, `docs/`, each with a README that fixes its purpose
  and file format.
- `patina` entry point with `help` and `version`; every other command reports that it is
  planned.
- Project documentation: README, CLAUDE.md, roadmap, branding and hardware notes.
- CI: shellcheck and yamllint; smoke run in openSUSE Tumbleweed containers on x86_64 and
  aarch64.

[Unreleased]: https://github.com/patina21/patina21/commits/main
