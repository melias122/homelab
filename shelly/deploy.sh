#!/usr/bin/env bash
# The Hue API key is baked in at deploy time so the committed script only
# carries the __HUE_KEY__ placeholder. The script slot (id 1) was created once
# with Script.Create.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/shelly/rpc.sh"
SHELLY=192.168.1.70 # shellyplus1pm-d4d4da3595f4 (pracovna), reserved in router-home dhcpd4.nix
SCRIPT_ID=1
SRC="$REPO/shelly/pracovna-hue-toggle.js"

KEY=$(cd "$REPO/secrets" && nix run github:ryantm/agenix/0.15.0 -- -d hue-shelly-key.age -i ~/.ssh/id_ed25519 2>/dev/null)
[ -n "$KEY" ] || { echo "failed to decrypt secrets/hue-shelly-key.age" >&2; exit 1; }

PASS=$(cd "$REPO/secrets" && nix run github:ryantm/agenix/0.15.0 -- -d shelly-auth.age -i ~/.ssh/id_ed25519 2>/dev/null)
[ -n "$PASS" ] || { echo "failed to decrypt secrets/shelly-auth.age" >&2; exit 1; }

shelly_auth "$SHELLY" "$PASS"

KEY="$KEY" SRC="$SRC" SCRIPT_ID="$SCRIPT_ID" python3 - <<'EOF' |
import json, os

code = open(os.environ["SRC"]).read().replace("__HUE_KEY__", os.environ["KEY"])
assert "__HUE_KEY__" not in code
sid = int(os.environ["SCRIPT_ID"])

def rpc(method, params):
    print(json.dumps({"id": 0, "method": method, "params": params}))

rpc("Script.Stop", {"id": sid})
CHUNK = 900
for n in range(0, len(code), CHUNK):
    rpc("Script.PutCode", {"id": sid, "code": code[n:n+CHUNK], "append": n > 0})
rpc("Script.SetConfig", {"id": sid, "config": {"enable": True}})
rpc("Script.Start", {"id": sid})
rpc("Script.GetStatus", {"id": sid})
EOF
while IFS= read -r payload; do
  shelly_rpc "$SHELLY" "$payload"
  echo
done
