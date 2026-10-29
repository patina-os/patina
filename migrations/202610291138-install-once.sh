#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# `patina update` now ends with an install of this machine's bundles, but an update made
# by the script before it runs only the migrations. This one runs that install once, so
# kortex 0.1.2 and whatever else the bundles, the system files and the app settings
# gained arrive with such an update too. Idempotent like the install itself; a fresh
# install needs none of this.
set -euo pipefail

exec "$PATINA_PATH/bin/patina" install --unattended
