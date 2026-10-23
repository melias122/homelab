#!/usr/bin/env bash
# TUV circulation pump schedule (Shelly 1PM Gen4). The whole job list is
# replaced on every run so the device never drifts from this file.
#
# toggle_after is only the cap: shelly/cerpadlo-tuv-stop.js ends a run once the
# return is warm.
#
# "on, off after N s" rather than toggle: a manual press, HA or a mid-day
# reboot cannot invert the cycle.
#
# Only shower windows run. Thinning the cadence saves nothing (night test
# 2026-10-22: a run after 30-90 min re-heats pipe and slab, 0.7-2.6 K of tank
# each, about what 15-min runs cost per hour); only hours fully off do.
#
# The device accepts "*/5" and "6-8", but the Shelly app only renders explicit
# lists and shows nothing otherwise, so everything is spelled out.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/shelly/rpc.sh"
SHELLY=192.168.1.78 # shelly1pmg4-e4b063768a78 (cerpadlo-tuv), reserved in router-home dhcpd4.nix

PASS=$(cd "$REPO/secrets" && nix run github:ryantm/agenix/0.15.0 -- -d shelly-auth.age -i ~/.ssh/id_ed25519 2>/dev/null)
[ -n "$PASS" ] || { echo "failed to decrypt secrets/shelly-auth.age" >&2; exit 1; }

shelly_auth "$SHELLY" "$PASS"

run() { printf '%-22s ' "$1"; shelly_rpc "$SHELLY" "{\"id\":0,\"method\":\"$1\",\"params\":$2}"; echo; }
job() { run Schedule.Create "{\"enable\":true,\"timespec\":\"$1\",\"calls\":[{\"method\":\"switch.set\",\"params\":{\"id\":0,$2}}]}"; }

# Pre-heat: from a loop cold for hours 35 °C takes > 7 min. Runs in a window
# mostly stop at 35 °C within 75-180 s.
PREHEAT='"on":true,"toggle_after":600'
ON240='"on":true,"toggle_after":240'
DAYS=SUN,MON,TUE,WED,THU,FRI,SAT
WORK=MON,TUE,WED,THU,FRI
WEEKEND=SAT,SUN
list() { seq -s, "$@" | sed "s/,$//"; }  # BSD seq leaves a trailing comma
every() { list 0 "$1" 59; }               # minute list with the given step

run Schedule.DeleteAll '{}'
job "0 45 5 * * $WORK"                                  "$PREHEAT" # up at 6:00
job "0 $(every 15) $(list 6 12) * * $WORK"                "$ON240"   # showers until 9:00, sometimes up to 13:00
job "0 45 6 * * $WEEKEND"                               "$PREHEAT" # up at 7:00
job "0 $(every 15) $(list 7 12) * * $WEEKEND"             "$ON240"   # showers until 9-10, sometimes up to 13:00
job "0 45 18 * * $DAYS"                                 "$PREHEAT" # kids' bath from 19:00
job "0 $(every 15) $(list 19 21) * * $DAYS"               "$ON240"   # until 21:00, sometimes 22:00
job "0 1 0 * * $DAYS"                                   '"on":false' # safety off after midnight
run Schedule.List '{}'
