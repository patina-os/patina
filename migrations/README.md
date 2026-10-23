# migrations/

Versioned update steps, Omarchy-style. `patina update` runs `git pull`, then every
migration that has not run yet, in filename order, and records each one as a marker file
in `~/.local/state/patina/migrations/`.

Naming: `YYYYMMDDHHMM-<slug>.sh`, for example `202611031400-move-theme-state.sh`. The
timestamp is when the migration was written (UTC); the slug says what it does.

Rules:

- Idempotent: running it twice must be harmless, because a user may re-run `patina update`.
- Small: one change per migration, a few lines, shellcheck-clean, no prompts.
- Never destructive without a backup next to the file it changes.
- Same conventions as `bin/` (see `CLAUDE.md`). It may call `patina` subcommands.
- `_template.sh` is the skeleton; tools skip entries starting with `_`.

Migrations exist for installed users only. A fresh `patina install` already produces the
end state, so no migration may be required for a fresh install to work; the first
`patina install` on a machine records every existing migration as done. `patina migrate
--list` prints the pending ones, `patina migrate` runs them without pulling.
