// Talks to the Hue bridge directly so the wall button works when Home
// Assistant is down. The ramp is a single bri_inc in the bulbs (no stepping).
// If the bridge does not answer a tap, power-cycle the bulbs via the relay:
// startup=safety turns them ON when power returns.

let BRIDGE = "192.168.1.60";
let KEY = "__HUE_KEY__"; // baked in by shelly/deploy.sh
let GROUP = "81"; // Hue room: Pracovna
let TIMEOUT = 3;
let HOLD_MS = 400;
let RAMP = 40; // 100 ms units

let busy = false; // rapid taps must not race
let holdTimer = null;
let holding = false;
let dimUp = true;

function gurl(path) {
  return "http://" + BRIDGE + "/api/" + KEY + "/groups/" + GROUP + path;
}

function put(body, cb) {
  Shelly.call(
    "HTTP.Request",
    { method: "PUT", url: gurl("/action"), body: JSON.stringify(body), timeout: TIMEOUT },
    function (r, e) {
      if (cb) cb(e === 0 && r !== null && r.code === 200);
    }
  );
}

function relayToggle() {
  Shelly.call("Switch.Toggle", { id: 0 });
}

function tapToggle() {
  Shelly.call("HTTP.GET", { url: gurl(""), timeout: TIMEOUT }, function (res, err) {
    if (err !== 0 || res === null || res.code !== 200) {
      relayToggle();
      return;
    }
    let anyOn = JSON.parse(res.body).state.any_on;
    put({ on: !anyOn }, function (ok) {
      if (!ok) relayToggle();
    });
  });
}

function holdStart() {
  holding = true;
  Shelly.call("HTTP.GET", { url: gurl(""), timeout: TIMEOUT }, function (res, err) {
    if (err !== 0 || res === null || res.code !== 200) return; // power-cycling on hold would be surprising
    let anyOn = JSON.parse(res.body).state.any_on;
    if (!anyOn) {
      put({ on: true, bri: 1 }, function () {
        put({ bri_inc: 254, transitiontime: RAMP });
      });
      dimUp = false;
      return;
    }
    put({ bri_inc: dimUp ? 254 : -254, transitiontime: RAMP });
    dimUp = !dimUp;
  });
}

function holdStop() {
  holding = false;
  put({ bri_inc: 0 }); // stops the ramp where it is
}

Shelly.addEventHandler(function (ev) {
  if (ev.component !== "input:0" || !ev.info) return;
  let e = ev.info.event;
  if (e === "btn_down") {
    if (holdTimer !== null) Timer.clear(holdTimer);
    holdTimer = Timer.set(HOLD_MS, false, function () {
      holdTimer = null;
      holdStart();
    });
    return;
  }
  if (e !== "btn_up") return;
  if (holdTimer !== null) {
    Timer.clear(holdTimer);
    holdTimer = null;
    if (busy) return;
    busy = true;
    Timer.set(1200, false, function () { busy = false; });
    Shelly.call("Switch.GetStatus", { id: 0 }, function (st) {
      // A previous fallback may have left the relay OFF; startup=safety turns
      // the bulbs on with the power, so this press means "light on".
      if (st && st.output === false) {
        Shelly.call("Switch.Set", { id: 0, on: true });
        return;
      }
      tapToggle();
    });
    return;
  }
  if (holding) holdStop();
});
