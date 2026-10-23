# devices/

The only place where architecture- or device-specific files may live. Everything else in
the repository is architecture-free; the base (Debian) carries the hardware support.

An "ARM version" of patina is never a separate release or branch. It is the tested
hardware list in `docs/hardware.md` plus, where a device needs it, a directory here.

```text
devices/<slug>/
  device.yaml       what the device is and what it needs (required); laptops that differ
                    only in their device tree share one directory and are listed under `models`
  README.md         how to get Debian onto it, known caveats (recommended)
  *.sh              glue scripts, only when data cannot express it (firmware extraction)
```

Rules:

- A device directory is added only once the device boots Debian's kernel, even if only
  with caveats or from backports; wishes go to the roadmap and `docs/hardware.md`.
- Glue scripts follow the `bin/` conventions and run only when `patina` detects that device.
- No kernel patches, no out-of-tree modules, no firmware blobs committed to the repository.
  A firmware helper may copy files from a vendor partition on the user's own machine.

`_template/` is the skeleton to copy; tools skip entries starting with `_`.
