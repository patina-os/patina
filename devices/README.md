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
  system/           system files, installed under /etc at the same path (as
                    defaults/system/ is) when `patina` detects the device (optional)
  *.sh              glue scripts, only when data cannot express it (firmware extraction)
```

`patina install` detects a device by the `detect` map of its `device.yaml`: fields of
`/sys/class/dmi/id` and the value each must equal, all of them. A detected device adds
its `extra_packages` to the install and its `system/` files to the system tuning, and
`patina doctor` checks both. A device without `detect` is never detected; its README
says what to do by hand.

Rules:

- A device directory is added only once the device boots Debian's kernel, even if only
  with caveats or from backports; wishes go to the roadmap and `docs/hardware.md`.
- Glue scripts follow the `bin/` conventions and run only when `patina` detects that device.
- Detect a device by what only it reports (a product name, not a vendor that covers a
  whole family), so no other machine is matched.
- No kernel patches, no out-of-tree modules, no firmware blobs committed to the repository.
  A firmware helper may copy files from a vendor partition on the user's own machine.

`_template/` is the skeleton to copy; tools skip entries starting with `_`.
