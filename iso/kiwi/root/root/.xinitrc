#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# X session of the live ISO: a bare window manager and Firefox in kiosk mode on Agama.
set -euo pipefail

xsetroot -solid '#1e1e1e' || true
icewm-session &
# Agama's web server listens on localhost; the certificate is self-signed, so use the
# plain http port it keeps for the local UI.
until curl -fsS -o /dev/null http://localhost/; do
  sleep 1
done
exec firefox --kiosk --private-window http://localhost/
