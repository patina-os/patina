# desktops/

One directory per desktop environment. It holds the templates and the one thin script
that render `themes/` and `defaults/` into that desktop's configuration.

```text
desktops/<desktop>/
  README.md         what the renderer produces and which tools it calls
  apply.sh          `apply.sh <theme-dir>`: render templates, write config, reload (Phase 2)
  templates/        config files with ${BASE00}-style placeholders filled by envsubst
```

Contract:

- Input is only data: a theme directory, `defaults/` and the user's overrides.
- A desktop never reads or writes another desktop's directory.
- Output lands in the user's XDG config and data directories; the repository checkout
  stays untouched, so `git pull` keeps working.
- Rendering is idempotent: running it twice yields the same files.

`plasma/` is the first and reference desktop. A later `hyprland/` must work from the same
theme data without changes to `themes/`.
