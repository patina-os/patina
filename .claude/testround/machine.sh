#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The test round's machines: a Debian 13 image with Plasma, patina by Path A and kortex.
set -euo pipefail

usage() {
  cat << USAGE
usage: machine.sh image [--rebuild]   build patina-tr:latest (once; --rebuild anew)
       machine.sh up <name>           start a machine from it, as container tr-<name>
       machine.sh sh <name> [cmd…]    a shell (or a command) as the user patina in it
       machine.sh down <name>         remove it

Runs on the host with Docker. The image is Path A from the checkouts beside this one:
PATINA_SRC (default: this repository) is copied to ~/.local/share/patina and
KORTEX_SRC (default: ../kortex beside it) is installed over the pinned release, so a
round tests the working tree. The agent is opencode with "Your own" API:
TR_API_URL (default https://api.franconia.ai/v1) and TR_API_MODEL (default
"Qwen 3.6 27B"); the key file holds a placeholder, since the session's proxy adds the
real key. Each machine shares the host's network, so the proxy and its CA are used.
USAGE
}

here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
PATINA_SRC="${PATINA_SRC:-$(cd "$here/../.." && pwd)}"
KORTEX_SRC="${KORTEX_SRC:-$(cd "$PATINA_SRC/.." && pwd)/kortex}"
api_url="${TR_API_URL:-https://api.franconia.ai/v1}"
api_model="${TR_API_MODEL:-Qwen 3.6 27B}"
ca="${TR_CA:-/root/.ccr/ca-bundle.crt}"
image=patina-tr:latest

docker_up() {
  docker info > /dev/null 2>&1 && return
  (dockerd > /tmp/dockerd.log 2>&1 &)
  for _ in $(seq 30); do docker info > /dev/null 2>&1 && return; sleep 1; done
  echo "machine.sh: dockerd did not start (/tmp/dockerd.log)" >&2
  exit 1
}

run_args() {
  local a=(--network host --privileged -e LANG=C.UTF-8)
  local v
  for v in HTTPS_PROXY HTTP_PROXY https_proxy http_proxy NO_PROXY no_proxy; do
    [[ -n "${!v:-}" ]] && a+=(-e "$v=${!v}")
  done
  [[ -s "$ca" ]] && a+=(-v "$ca:/usr/local/share/ca-certificates/session-proxy.crt:ro"
    -e NODE_EXTRA_CA_CERTS=/usr/local/share/ca-certificates/session-proxy.crt)
  a+=(-v "$PATINA_SRC:/src/patina:ro" -v "$KORTEX_SRC:/src/kortex:ro")
  printf '%s\n' "${a[@]}"
}

build() {
  local args c=tr-build
  mapfile -t args < <(run_args)
  docker rm -f "$c" > /dev/null 2>&1 || true
  docker run -d --name "$c" "${args[@]}" debian:13 sleep infinity > /dev/null
  docker exec -i "$c" bash -euo pipefail << 'IN'
# docker exec starts with umask 0000, which leaves files world-writable: sudo ignores a
# sudoers file that is.
umask 022
update-ca-certificates > /dev/null 2>&1 || true
apt-get update -q
# What patina's desktop workflow starts from, the D-Bus Python kortex's tools need, and
# rsync for copying the checkouts.
DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  plasma-desktop plasma-workspace kwin-x11 xvfb scrot xdotool dolphin firefox-esr dbus \
  libgl1-mesa-dri libegl-mesa0 git ca-certificates curl sudo python3-dbus python3-gi \
  dbus-x11 rsync procps > /dev/null
useradd --create-home --shell /bin/bash patina
echo 'patina ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/patina
chmod 440 /etc/sudoers.d/patina
mkdir -p /run/dbus
# Path A: the checkout at ~/.local/share/patina, then patina install as the user, with
# opencode on the user's own API (what patina ai login would have written).
sudo -u patina -H bash -euo pipefail << 'USER'
mkdir -p ~/.local/share ~/.local/state/patina ~/.config/patina/ai
rsync -a --exclude .claude /src/patina/ ~/.local/share/patina/
USER
IN
  # yq comes with the install, so the endpoint file is written plainly (two strings).
  docker exec -u patina -e HOME=/home/patina "$c" bash -c "umask 077
    printf 'url: \"%s\"\nmodel: \"%s\"\n' '$api_url' '$api_model' > ~/.local/state/patina/ai-endpoint.yaml
    printf 'placeholder-the-proxy-adds-the-key\n' > ~/.config/patina/ai/custom.key
    chmod 600 ~/.config/patina/ai/custom.key"
  docker exec "$c" bash -c 'pgrep dbus-daemon > /dev/null || dbus-daemon --system --fork'
  docker exec -u patina -w /home/patina/.local/share/patina \
    -e HOME=/home/patina -e PATINA_AI=cloud -e PATINA_AI_AGENT=opencode -e PATINA_AI_PROVIDER=custom \
    "$c" bash -c 'umask 022; exec bin/patina install --unattended --bundles desktop'
  # kortex from the working tree over the pinned release.
  docker exec -u patina -e HOME=/home/patina "$c" bash -c \
    'umask 022; rm -rf ~/kortex-src && cp -r /src/kortex ~/kortex-src && cd ~/kortex-src && ./install.sh'
  docker commit "$c" "$image" > /dev/null
  docker rm -f "$c" > /dev/null
  echo "machine.sh: $image built"
}

cmd="${1:-}"
case "$cmd" in
  image)
    docker_up
    if [[ "${2:-}" == --rebuild ]] || ! docker image inspect "$image" > /dev/null 2>&1; then
      build
    else
      echo "machine.sh: $image exists (--rebuild to build it anew)"
    fi
    ;;
  up)
    [[ -n "${2:-}" ]] || { usage; exit 2; }
    docker_up
    mapfile -t args < <(run_args)
    docker rm -f "tr-$2" > /dev/null 2>&1 || true
    docker run -d --name "tr-$2" --hostname "tr-$2" "${args[@]}" "$image" sleep infinity > /dev/null
    docker exec "tr-$2" bash -c 'umask 022; update-ca-certificates > /dev/null 2>&1; mkdir -p /run/dbus; dbus-daemon --system --fork'
    echo "machine.sh: tr-$2 up"
    ;;
  sh)
    [[ -n "${2:-}" ]] || { usage; exit 2; }
    name="$2"
    shift 2
    if (($#)); then
      docker exec -i -u patina -w /home/patina -e HOME=/home/patina \
        -e PATH=/home/patina/.local/bin:/usr/local/bin:/usr/bin:/bin "tr-$name" bash -lc "umask 022; $*"
    else
      docker exec -it -u patina -w /home/patina -e HOME=/home/patina "tr-$name" bash -lc 'umask 022; exec bash -l'
    fi
    ;;
  down)
    [[ -n "${2:-}" ]] || { usage; exit 2; }
    docker rm -f "tr-$2" > /dev/null 2>&1 || true
    ;;
  *) usage; [[ "$cmd" == -h || "$cmd" == --help ]] ;;
esac
