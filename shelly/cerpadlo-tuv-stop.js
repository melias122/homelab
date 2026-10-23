// Ends a TUV circulation run once the return probe reaches its threshold: a
// still-warm loop is not pushed further, a cold one runs until it is warm.
// Scheduled runs are capped by their toggle_after (also if the probe is gone);
// manual runs from HA have no timer, so the script caps them itself.

// Showers are ~37 °C (not measured precisely). The return settles ~3-5 K under
// the tank and the tank restarts at ~39.5, so 38 was often out of reach.
let STOP_C = 35;
// A manual run means someone wants hot water now.
let MANUAL_STOP_C = 36;
// From a loop cold for hours 35 °C takes > 7 min (night of 2026-10-22).
let MANUAL_MAX_S = 900;
// With the pump off the probe reads the stagnant stub in the technical room,
// which cools faster than the loop; loop water needs ~30 s to reach it plus
// ~30 s probe lag before the reading means anything.
let MIN_S = 60;
let POLL_S = 5;

let timer = null;
let elapsed = 0;
let stopC = STOP_C;
let maxS = 0; // 0 = toggle_after caps the run

function off(why) {
  print(why + ", stopping");
  Shelly.call("Switch.Set", { id: 0, on: false });
  done();
}

function done() {
  if (timer !== null) Timer.clear(timer);
  timer = null;
}

function check() {
  elapsed += POLL_S;
  if (!Shelly.getComponentStatus("switch:0").output) {
    done();
    return;
  }
  if (maxS > 0 && elapsed >= maxS) {
    off("manual run at " + elapsed + " s");
    return;
  }
  if (elapsed < MIN_S) return;
  let t = Shelly.getComponentStatus("temperature:100").tC;
  if (typeof t !== "number" || t < stopC) return;
  off("return " + t + " C after " + elapsed + " s");
}

Shelly.addStatusHandler(function (ev) {
  if (ev.component !== "switch:0" || !ev.delta || ev.delta.output !== true) return;
  // Schedule jobs switch via loopback; HA and the app report other sources.
  let scheduled = Shelly.getComponentStatus("switch:0").source === "loopback";
  stopC = scheduled ? STOP_C : MANUAL_STOP_C;
  maxS = scheduled ? 0 : MANUAL_MAX_S;
  done();
  elapsed = 0;
  timer = Timer.set(POLL_S * 1000, true, check);
});
