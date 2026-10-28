#!/usr/bin/env bash
# esphome CLI on the configs in this directory, e.g.
#   esphome/run.sh run paradox.yaml --device /dev/cu.usbserial-1110
# Builds in a cache dir outside the repo: `make deploy-*` rsyncs the whole tree to
# /etc/nixos, which must get neither the PlatformIO build nor the decrypted secrets.yaml.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${XDG_CACHE_HOME:-$HOME/.cache}/homelab-esphome"
mkdir -p "$WORK"
rsync -a --delete --exclude .esphome/ "$REPO/esphome/" "$WORK/"

trap 'rm -f "$WORK/secrets.yaml"' EXIT
(umask 077 && cd "$REPO/secrets" &&
  nix run github:ryantm/agenix/0.15.0 -- -d esphome-secrets.age -i ~/.ssh/id_ed25519 \
    >"$WORK/secrets.yaml" 2>/dev/null) ||
  { echo "failed to decrypt secrets/esphome-secrets.age" >&2; exit 1; }

cd "$WORK"
nix shell nixpkgs#esphome -c esphome "$@"
