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

ON180='"on":true,"toggle_after":180'
DAYS=SUN,MON,TUE,WED,THU,FRI,SAT
list() { seq -s, "$@" | sed "s/,$//"; }  # BSD seq leaves a trailing comma
every() { list 0 "$1" 59; }               # minute list with the given step

run Schedule.DeleteAll '{}'
job "0 45 5 * * $DAYS"                                  '"on":true,"toggle_after":300' # morning pre-heat
# 2026-09-27: one flat cadence instead of 5 min peaks / 15 min off-peak. The
# loop takes ~150 s to turn over (return pipe measured by hand), so the old
# 90 s runs never brought hot water to the far bathrooms.
job "0 $(every 15) $(list 6 23) * * $DAYS"                "$ON180"                       # 180 s every 15 min, 6:00-23:45
job "0 1 0 * * $DAYS"                                   '"on":false'                   # safety off after midnight
run Schedule.List '{}'
