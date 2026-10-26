#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The desktop now takes the theme's colours (they are copied into kdeglobals) and
# aurora's icons are Papirus with folders in the accent. A run of `patina install`
# brings both: it installs papirus-icon-theme from the desktop bundle and renders the
# theme already set here again, keeping the user's choice of theme and their panels.
# Idempotent like the install itself; a fresh install needs none of this.
set -euo pipefail

exec "$PATINA_PATH/bin/patina" install --unattended
