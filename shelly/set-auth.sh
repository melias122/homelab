#!/usr/bin/env bash
# Without auth anyone on the flat LAN (guest phones, cloud IoT devices) can flip
# the relays, reflash the device or read the Hue API key out of the script on .70.
#
# Idempotent; re-run after adding a device or changing the password. To turn
# auth off: Shelly.SetAuth {"user":"admin","realm":"<device id>","ha1":null}.
# HA keeps its own copy in .storage and needs a reauth per device after a change.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/shelly/rpc.sh"

DEVICES=(
  192.168.1.70 # svetlo-pracovna
  192.168.1.71 # zaluzia-pracovna
  192.168.1.72 # zaluzia-obyvacka-hsportal
  192.168.1.73 # zaluzia-obyvacka-fix
  192.168.1.74 # zaluzia-detska-prizemie-fix
  192.168.1.75 # zaluzia-detska-prizemie-zahrada
  192.168.1.76 # zasuvka-cerpadlo-tuv
  192.168.1.77 # zavlaha
)

PASS=$(cd "$REPO/secrets" && nix run github:ryantm/agenix/0.15.0 -- -d shelly-auth.age -i ~/.ssh/id_ed25519 2>/dev/null)
[ -n "$PASS" ] || { echo "failed to decrypt secrets/shelly-auth.age" >&2; exit 1; }

for ip in "${DEVICES[@]}"; do
  # /shelly answers without auth even once auth is on.
  id=$(ssh root@server "curl -s -m 10 http://$ip/shelly" |
    grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$id" ] || { echo "$ip: no answer, skipped" >&2; continue; }
  shelly_auth "$ip" "$PASS"

  # Digest realm is the device id, ha1 = SHA256("admin:<realm>:<password>").
  ha1=$(printf '%s' "admin:$id:$PASS" | sha256)
  out=$(shelly_rpc "$ip" "{\"id\":0,\"method\":\"Shelly.SetAuth\",\"params\":{\"user\":\"admin\",\"realm\":\"$id\",\"ha1\":\"$ha1\"}}")
  case "$out" in *error*) echo "$ip: $out" >&2 ;; esac

  auth=$(ssh root@server "curl -s -m 10 http://$ip/shelly" | grep -o '"auth_en":[a-z]*')
  echo "$ip $id -> $auth"
done
