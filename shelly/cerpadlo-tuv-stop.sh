#!/usr/bin/env bash
# Uploads cerpadlo-tuv-stop.js to the TUV pump Shelly. The script slot (id 1)
# was created once with Script.Create.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/shelly/rpc.sh"
SHELLY=192.168.1.78 # shelly1pmg4-e4b063768a78 (cerpadlo-tuv), reserved in router-home dhcpd4.nix
SCRIPT_ID=1
SRC="$REPO/shelly/cerpadlo-tuv-stop.js"

PASS=$(cd "$REPO/secrets" && nix run github:ryantm/agenix/0.15.0 -- -d shelly-auth.age -i ~/.ssh/id_ed25519 2>/dev/null)
[ -n "$PASS" ] || { echo "failed to decrypt secrets/shelly-auth.age" >&2; exit 1; }

shelly_auth "$SHELLY" "$PASS"

SRC="$SRC" SCRIPT_ID="$SCRIPT_ID" python3 - <<'EOF' |
import json, os

code = open(os.environ["SRC"]).read()
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
