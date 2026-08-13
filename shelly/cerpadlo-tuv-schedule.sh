#!/usr/bin/env bash
# TUV circulation pump schedule (Shelly Plus Plug S). The whole job list is
# replaced on every run so the device never drifts from this file.
#
# "on, off after N s" rather than toggle: a manual press, HA or a mid-day
# reboot cannot invert the cycle. Between runs the loop cools a bit, which is
# where the savings are.
#
# The device accepts "*/5" and "6-8", but the Shelly app only renders explicit
# lists and shows nothing otherwise, so everything is spelled out.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/shelly/rpc.sh"
SHELLY=192.168.1.76 # shellyplusplugs-d4d4daec69ac (zasuvka-cerpadlo-tuv), reserved in router-home dhcpd4.nix

PASS=$(cd "$REPO/secrets" && nix run github:ryantm/agenix/0.15.0 -- -d shelly-auth.age -i ~/.ssh/id_ed25519 2>/dev/null)
[ -n "$PASS" ] || { echo "failed to decrypt secrets/shelly-auth.age" >&2; exit 1; }

shelly_auth "$SHELLY" "$PASS"

run() { printf '%-22s ' "$1"; shelly_rpc "$SHELLY" "{\"id\":0,\"method\":\"$1\",\"params\":$2}"; echo; }
job() { run Schedule.Create "{\"enable\":true,\"timespec\":\"$1\",\"calls\":[{\"method\":\"switch.set\",\"params\":{\"id\":0,$2}}]}"; }

ON90='"on":true,"toggle_after":90'
DAYS=SUN,MON,TUE,WED,THU,FRI,SAT
every() { seq -s, 0 "$1" 59 | sed "s/,$//"; } # minute list with the given step (BSD seq leaves a trailing comma)

run Schedule.DeleteAll '{}'
job "0 45 5 * * $DAYS"                                  '"on":true,"toggle_after":300' # morning pre-heat
job "0 $(every 5) 6,7,8,9,19,20,21,22 * * $DAYS"        "$ON90"                        # peaks: 90 s every 5 min (showers 6-9, 19-22)
job "0 $(every 15) 10,11,12,13,14,15,16,17,18,23 * * $DAYS" "$ON90"                    # off-peak: 90 s every 15 min
job "0 1 0 * * $DAYS"                                   '"on":false'                   # safety off after midnight
run Schedule.List '{}'
