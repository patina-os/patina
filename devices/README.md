# devices/

The only place where architecture- or device-specific files may live. Everything else in
the repository is architecture-free; the base (openSUSE) carries the hardware support.

An "ARM version" of patina21 is never a separate release or branch. It is the tested
hardware list in `docs/hardware.md` plus, where a device needs it, a directory here.

```text
devices/<slug>/
  device.yaml       what the device is and what it needs (required)
  README.md         how to get openSUSE onto it, known caveats (recommended)
  *.sh              glue scripts, only when data cannot express it (firmware extraction)
```

Rules:

- A device directory is added only once the device boots openSUSE; wishes go to the roadmap.
- Glue scripts follow the `bin/` conventions and run only when `patina` detects that device.
- No kernel patches, no out-of-tree modules, no firmware blobs committed to the repository.
  A firmware helper may copy files from a vendor partition on the user's own machine.

`_template/` is the skeleton to copy; tools skip entries starting with `_`.
