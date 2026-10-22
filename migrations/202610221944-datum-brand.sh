#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The datum redesign on an installed machine: the desktop bundle gained the fonts it is
# set in (Source Sans 3, Sora), and the splash, the greeting and the interface font come
# from the theme renderer. A run of `patina install` brings both: it installs what the
# bundles name and renders the theme already set here again, keeping the user's choice
# of theme and their panels. Idempotent like the install itself; a fresh install needs
# none of this.
set -euo pipefail

exec "$PATINA_PATH/bin/patina" install --unattended
