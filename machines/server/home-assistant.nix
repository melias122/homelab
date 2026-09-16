{ config, lib, pkgs, ... }:

let
  # Morning tilt at max(sunrise, `morningAt`): winter sunrises would open the
  # blinds in the dark, summer ones at 05:00. A manual move starts the blind's
  # timer and the automations leave it alone while it runs; the timer expires
  # on its own, so a forgotten override can't disable the automation for good.
  # Tilt works because all five Shellys have slat control calibrated.
  blinds = [
    { key = "zaluzie_pracovna"; cover = "cover.zaluzia_pracovna"; label = "Žalúzie pracovňa"; }
    # Terrace door: an automatic close can lock somebody out and there is no
    # door sensor yet, so a manual raise during the day keeps the sunset close
    # away all evening, while an untouched day still closes. Shorten once a
    # door sensor exists. The 16h window would swallow the morning tilt after
    # every evening close by hand, and tilting slats can't trap anyone.
    { key = "zaluzie_obyvacka_hsportal"; cover = "cover.zaluzia_obyvacka_hsportal"; label = "Žalúzie obývačka hsportál"; manualDuration = "16:00:00"; morningIgnoresManual = true; }
    { key = "zaluzie_obyvacka_fix"; cover = "cover.zaluzia_obyvacka_fix"; label = "Žalúzie obývačka fix"; }
    { key = "zaluzie_detska_prizemie_fix"; cover = "cover.zaluzia_detska_prizemie_fix"; label = "Žalúzie detská prízemie fix"; }
    { key = "zaluzie_detska_prizemie_zahrada"; cover = "cover.zaluzia_detska_prizemie_zahrada"; label = "Žalúzie detská prízemie záhrada"; }
  ];

  manualDurationOf = b: b.manualDuration or "02:00:00";
  # Jinja expression, zero-padded HH:MM: 06:30 Mon–Fri, 07:00 Sat/Sun.
  morningAt = "('07:00' if now().weekday() >= 5 else '06:30')";

  manualTimer = c: "timer.${c.key}_manual";

  # Komfovent C6 rekuperacia (192.168.1.119, Modbus TCP). No nixpkgs package
  # and no HACS on this host. pymodbus is only in the HA closure when a modbus
  # component is enabled, so the manifest requirement is added by hand.
  komfovent = pkgs.buildHomeAssistantComponent rec {
    owner = "lnagel";
    domain = "komfovent";
    version = "0.10.4";

    src = pkgs.fetchFromGitHub {
      owner = "lnagel";
      repo = "hass-komfovent";
      tag = "v${version}";
      hash = "sha256-NS6n6mFBh5DN+z+e4wh1uALtA5dFyzrice/uomPc2Rg=";
    };

    dependencies = [ config.services.home-assistant.package.python3Packages.pymodbus ];

    meta = {
      description = "Home Assistant integration for Komfovent C6/C6M/C8 air handling units";
      homepage = "https://github.com/lnagel/hass-komfovent";
      license = pkgs.lib.licenses.mit;
    };
  };

  # EZVIZ HP7 Pro intercom (zvoncek). No native RTSP/ONVIF and the core
  # `ezviz` integration builds cameras from local RTSP so it can't add it
  # (https://github.com/home-assistant/core/issues/136070); no HACS on this host.
  #
  # TODO(zvoncek live stream): broken on doorbell firmware V5.4.x, the relay's
  # ffmpeg can't parse the stream (https://github.com/Bobsilvio/ezviz_hp7/issues/51).
  # When a release fixes it, bump this pin and re-enable the camera in
  # ./frigate-config.yml. Unlock/sensors/snapshots work.
  ezviz-hp7 = pkgs.buildHomeAssistantComponent rec {
    owner = "Bobsilvio";
    domain = "ezviz_hp7";
    version = "0.18.1";

    src = pkgs.fetchFromGitHub {
      owner = "Bobsilvio";
      repo = "ezviz_hp7";
      tag = "v${version}";
      hash = "sha256-azQUcYfcuZLV6HEItYLpEIie1r5Cw2NvVd19pTSfJJ8=";
    };

    # A failed forced re-login leaves a client without a token and unlock dies
    # silently until HA restarts (3 days of a dead gate button, 2026-08-25).
    # Drop once a release carries https://github.com/Bobsilvio/ezviz_hp7/issues/59.
    patches = [ ./ezviz-hp7-relogin.patch ];

    dependencies = with config.services.home-assistant.package.python3Packages; [
      pycryptodome
      pandas
      requests
      paho-mqtt
      xmltodict
    ];

    meta = {
      description = "Home Assistant integration for the EZVIZ HP7 / CP7 video intercom";
      homepage = "https://github.com/Bobsilvio/ezviz_hp7";
      license = pkgs.lib.licenses.mit;
    };
  };

  mkManualDetector = c: {
    id = "${c.key}_manual_detekcia";
    alias = "${c.label}: zapamätať manuálny zásah";
    mode = "single";
    max_exceeded = "silent";
    triggers = [
      # Only the start of a move: the entity keeps the caller's context for 5 s,
      # later position updates would look like a hand on the switch.
      { trigger = "state"; entity_id = c.cover; to = [ "opening" "closing" ]; }
    ];
    conditions = [
      {
        condition = "template";
        # Our own sunset/morning runs are matched by context id, not parent_id:
        # sun/time triggers have no context, so neither does the run
        # (2026-09-12: every sunset close started the timer). Other automations
        # carry a parent; everything else is a human. The unavailable/unknown
        # guard keeps HA restarts from counting.
        value_template = ''
          {% set own = states.automation
               | selectattr('attributes.id', 'in', ['${c.key}_zapad', '${c.key}_vychod'])
               | map(attribute='context.id') | list %}
          {{ trigger.to_state.context.id not in own
             and trigger.to_state.context.parent_id is none
             and trigger.from_state is not none
             and trigger.from_state.state not in ['unavailable', 'unknown'] }}
        '';
      }
    ];
    actions = [
      # timer.start on a running timer restarts it: window from the last touch.
      { action = "timer.start"; target.entity_id = manualTimer c; }
    ];
  };

  manualIdle = c: {
    condition = "state";
    entity_id = manualTimer c;
    state = "idle";
  };

  mkSunset = b: {
    id = "${b.key}_zapad";
    alias = "${b.label}: dole pri západe slnka";
    triggers = [
      { trigger = "sun"; event = "sunset"; }
    ];
    conditions = [ (manualIdle b) ];
    actions = [
      { action = "cover.close_cover"; target.entity_id = b.cover; }
    ];
  };

  mkMorning = b: {
    id = "${b.key}_vychod";
    alias = "${b.label}: ráno odklopiť lamely, nie pred 6:30 (víkend 7:00)";
    # Both moments trigger; the conditions let only the later one through.
    # `now()` makes HA re-render the template every minute, so it fires once.
    triggers = [
      { trigger = "sun"; event = "sunrise"; }
      { trigger = "template"; value_template = "{{ now().strftime('%H:%M') == ${morningAt} }}"; }
    ];
    conditions = lib.optional (!(b.morningIgnoresManual or false)) (manualIdle b)
    ++ [
      # String compare; `>=` lets the exact-time trigger pass.
      {
        condition = "template";
        value_template = "{{ now().strftime('%H:%M') >= ${morningAt} }}";
      }
      # The sunrise event fires at elevation ~ -0.833°.
      {
        condition = "numeric_state";
        entity_id = "sun.sun";
        attribute = "elevation";
        above = -1;
      }
      # Shelly fw 2.0.0 answers a slat-only GoToPosition on a partly raised
      # blind by driving it down for ~15 s (hsportal 2026-08-26, 2026-09-03).
      {
        condition = "numeric_state";
        entity_id = b.cover;
        attribute = "current_position";
        below = 5;
      }
    ];
    actions = [
      { action = "cover.open_cover_tilt"; target.entity_id = b.cover; }
    ];
  };

  # Summer night flush: Intensive on the unit means 10 °C setpoint, i.e.
  # maximum free cooling. No season condition needed, `extract > 25 °C` is
  # only true in warm weather. The input_boolean marks "the automation
  # switched the mode", so the stop side only reverts what the start side
  # did and a mode picked by hand is left alone.
  rekuNightStart = {
    id = "rekuperacia_nocne_vetranie_start";
    alias = "Rekuperácia: nočné vetranie v lete — štart";
    mode = "single";
    triggers = [
      # Sampling: a numeric_state trigger only fires on the crossing, so a
      # condition already true when HA restarts (autoUpgrade, deploy) would never fire.
      { trigger = "time_pattern"; minutes = "/30"; }
      { trigger = "numeric_state"; entity_id = "sensor.rekuperacia_outdoor_temperature"; below = 20; }
    ];
    conditions = [
      { condition = "time"; after = "21:00:00"; before = "06:00:00"; }
      # Absolute thresholds: on 2026-08-20/21 outdoor 20.6 / house 26.4 cost
      # +68 W and audible fans for a 0.3 °C drop (ducts warm the supply ~2 °C).
      # numeric_state is false on an unavailable sensor, so a dead sensor
      # can never start the flush.
      { condition = "numeric_state"; entity_id = "sensor.rekuperacia_extract_temperature"; above = 25; }
      { condition = "numeric_state"; entity_id = "sensor.rekuperacia_outdoor_temperature"; below = 20; }
      # Any other mode means somebody chose it.
      { condition = "state"; entity_id = "climate.rekuperacia"; attribute = "preset_mode"; state = "normal"; }
      # See rekuManualDetector: 2026-09-10 set to Normal at 21:07, re-flushed at 21:30.
      { condition = "state"; entity_id = "timer.rekuperacia_manual"; state = "idle"; }
    ];
    actions = [
      { action = "input_boolean.turn_on"; target.entity_id = "input_boolean.rekuperacia_nocne_vetranie"; }
      { action = "climate.set_preset_mode"; target.entity_id = "climate.rekuperacia"; data.preset_mode = "intensive"; }
    ];
  };

  rekuNightStop = {
    id = "rekuperacia_nocne_vetranie_stop";
    alias = "Rekuperácia: nočné vetranie v lete — koniec";
    mode = "single";
    triggers = [
      # Stop at a 3 °C gap (start needs 5): below that the extra flow barely
      # does anything. float(99) on outdoor makes a dead sensor end the flush
      # rather than run it forever.
      { trigger = "numeric_state"; entity_id = "sensor.rekuperacia_extract_temperature"; below = 22; }
      {
        trigger = "template";
        value_template = "{{ states('sensor.rekuperacia_outdoor_temperature')|float(99) >= states('sensor.rekuperacia_extract_temperature')|float(0) - 3 }}";
      }
      { trigger = "time"; at = "06:00:00"; }
    ];
    conditions = [
      { condition = "state"; entity_id = "input_boolean.rekuperacia_nocne_vetranie"; state = "on"; }
      # A ~30 s Modbus dropout fires the template trigger (float(0) on extract),
      # the `if` below sees no preset_mode, the flag is cleared and the unit
      # comes back stuck in Intensive (2026-09-09 for 27 h, 2026-09-12).
      { condition = "not"; conditions = [{ condition = "state"; entity_id = "climate.rekuperacia"; state = [ "unavailable" "unknown" ]; }]; }
    ];
    actions = [
      # A mode changed by hand overnight stays; the flag is cleared either way.
      {
        "if" = [{ condition = "state"; entity_id = "climate.rekuperacia"; attribute = "preset_mode"; state = "intensive"; }];
        "then" = [{ action = "climate.set_preset_mode"; target.entity_id = "climate.rekuperacia"; data.preset_mode = "normal"; }];
      }
      { action = "input_boolean.turn_off"; target.entity_id = "input_boolean.rekuperacia_nocne_vetranie"; }
    ];
  };

  # Same idea as the blinds' manual timers; 12 h from an evening touch covers
  # the whole 21:00–06:00 window.
  rekuManualDetector = {
    id = "rekuperacia_manual_detekcia";
    alias = "Rekuperácia: zapamätať manuálny zásah";
    mode = "single";
    max_exceeded = "silent";
    triggers = [
      # `attribute`: the ~30 s temperature updates must not fire it.
      { trigger = "state"; entity_id = "climate.rekuperacia"; attribute = "preset_mode"; }
    ];
    conditions = [
      {
        condition = "template";
        # Automation-driven changes carry a parent context; everything else is
        # a human. Unavailable guard: Modbus dropouts and HA restarts. Override
        # is the unit reacting to its external input (hood, WC switch), not a choice.
        value_template = ''
          {{ trigger.to_state.context.parent_id is none
             and trigger.from_state is not none
             and trigger.from_state.state not in ['unavailable', 'unknown']
             and trigger.to_state.state not in ['unavailable', 'unknown']
             and 'override' not in [trigger.from_state.attributes.preset_mode, trigger.to_state.attributes.preset_mode] }}
        '';
      }
    ];
    actions = [
      { action = "timer.start"; target.entity_id = "timer.rekuperacia_manual"; }
    ];
  };

  # The clogging estimate reads higher at Intensive, so a threshold trigger
  # would fire from the night flush; sample daily and only while Normal.
  rekuFilterNotify = {
    id = "rekuperacia_notifikacia_filter";
    alias = "Rekuperácia: notifikácia — zanesené filtre";
    triggers = [ { trigger = "time"; at = "09:00:00"; } ];
    conditions = [
      { condition = "numeric_state"; entity_id = "sensor.rekuperacia_filter_clogging"; above = 85; }
      { condition = "state"; entity_id = "climate.rekuperacia"; attribute = "preset_mode"; state = "normal"; }
    ];
    actions = [
      {
        action = "notify.mobile_app_iphone_16_m";
        data = {
          title = "Rekuperácia";
          message = "Filtre sú zanesené na {{ states('sensor.rekuperacia_filter_clogging') }} % — čas ich vymeniť.";
        };
      }
    ];
  };

  rekuFaultNotify = {
    id = "rekuperacia_notifikacia_porucha";
    alias = "Rekuperácia: notifikácia — porucha";
    mode = "single";
    triggers = [
      { trigger = "state"; entity_id = "binary_sensor.rekuperacia_status_alarm_fault"; to = "on"; }
      # Warnings can be transient (icing protection in a cold snap).
      { trigger = "state"; entity_id = "binary_sensor.rekuperacia_status_alarm_warning"; to = "on"; "for" = "00:10:00"; }
    ];
    actions = [
      {
        action = "notify.mobile_app_iphone_16_m";
        data = {
          title = "Rekuperácia: porucha";
          message = "Aktívne alarmy: {{ states('sensor.rekuperacia_active_alarms') }}";
        };
      }
    ];
  };

  # The integration polls the EZVIZ cloud every 15 s (no local push), so the
  # notification lands 0–15 s after the chime. The snapshot camera holds the
  # last alarm picture, at that moment the ring itself; the companion app
  # resolves the relative camera_proxy path itself. `tag` makes a second ring
  # replace the first notification; `authenticationRequired` forces Face ID
  # before the gate opens from the lock screen.
  zvoncekPhones = [ "notify.mobile_app_iphone_16_m" "notify.mobile_app_lulu" ];

  zvoncekRingNotify = {
    id = "zvoncek_notifikacia_zvonenie";
    alias = "Zvonček: notifikácia — niekto zvoní";
    mode = "single";
    max_exceeded = "silent";
    triggers = [
      { trigger = "state"; entity_id = "binary_sensor.zvoncek_vchod_zvonenie"; to = "on"; }
    ];
    actions = map (svc: {
      action = svc;
      data = {
        title = "Zvonček";
        message = "Niekto zvoní pri bráne.";
        data = {
          tag = "zvoncek";
          image = "/api/camera_proxy/camera.zvoncek_vchod_last_snapshot";
          push = {
            sound = { name = "default"; critical = 0; };
            interruption-level = "time-sensitive";
          };
          actions = [
            { action = "ZVONCEK_BRANA"; title = "Otvoriť bránu"; activationMode = "background"; authenticationRequired = true; }
            { action = "ZVONCEK_DVERE"; title = "Otvoriť dvere"; activationMode = "background"; authenticationRequired = true; }
          ];
        };
      };
    }) zvoncekPhones;
  };

  # The companion app answers a tapped action with this event.
  zvoncekNotifyAction = {
    id = "zvoncek_otvorit_z_notifikacie";
    alias = "Zvonček: otvoriť bránu/dvere z notifikácie";
    mode = "queued";
    triggers = [
      { trigger = "event"; event_type = "mobile_app_notification_action"; event_data.action = "ZVONCEK_BRANA"; id = "brana"; }
      { trigger = "event"; event_type = "mobile_app_notification_action"; event_data.action = "ZVONCEK_DVERE"; id = "dvere"; }
    ];
    actions = [
      {
        choose = [
          { conditions = [{ condition = "trigger"; id = "brana"; }]; sequence = [{ action = "button.press"; target.entity_id = "button.zvoncek_vchod_brana"; }]; }
          { conditions = [{ condition = "trigger"; id = "dvere"; }]; sequence = [{ action = "button.press"; target.entity_id = "button.zvoncek_vchod_dvere"; }]; }
        ];
      }
    ];
  };

  # The schedule lives on the controller (06:00, lawn zones back to back) and
  # HA only reacts to the valves it opens, so a dead HA changes nothing.
  # `float(0)` on an unavailable rain sensor means "no rain": water rather
  # than skip on missing data.
  zavlahaVentily = [
    "valve.zavlaha_travnik_za_garazou"
    "valve.zavlaha_travnik_pri_dome"
    "valve.zavlaha_kvapkova"
  ];

  zavlahaRainSkip = {
    id = "zavlaha_preskocit_pri_dazdi";
    alias = "Závlaha: preskočiť pri daždi";
    mode = "queued";
    triggers = [
      { trigger = "state"; entity_id = zavlahaVentily; to = "open"; }
    ];
    conditions = [
      # Only the scheduled run; a valve opened by hand later is left alone.
      { condition = "time"; after = "05:55:00"; before = "07:00:00"; }
      {
        condition = "template";
        value_template = "{{ states('sensor.zavlaha_zrazky')|float(0) > 5 }}";
      }
    ];
    actions = [
      { action = "valve.close_valve"; target.entity_id = "{{ trigger.entity_id }}"; }
      {
        action = "notify.mobile_app_iphone_16_m";
        data = {
          title = "Závlaha";
          message = "{{ state_attr(trigger.entity_id, 'friendly_name') }} preskočená, zrážky {{ states('sensor.zavlaha_zrazky') }} mm.";
        };
      }
    ];
  };

  # Scheduled runs take ~10 min; raise the limit if the drip zone ever gets a long program.
  zavlahaStuck = {
    id = "zavlaha_zaseknuty_ventil";
    alias = "Závlaha: zavrieť zaseknutý ventil";
    mode = "queued";
    triggers = [
      { trigger = "state"; entity_id = zavlahaVentily; to = "open"; "for" = "00:30:00"; }
    ];
    actions = [
      { action = "valve.close_valve"; target.entity_id = "{{ trigger.entity_id }}"; }
      {
        action = "notify.mobile_app_iphone_16_m";
        data = {
          title = "Závlaha: zaseknutý ventil";
          message = "{{ state_attr(trigger.entity_id, 'friendly_name') }} bol otvorený 30 min, zavreté automaticky.";
        };
      }
    ];
  };
in
{
  services.home-assistant = {
    enable = true;

    extraComponents = [
      # Needed to finish onboarding.
      "analytics"
      "google_translate"
      "met"
      "radio_browser"
      "shopping_list"
      # Faster zlib compression.
      "isal"

      "gree"
      "shelly"
      "hue"

      # Required by the frigate custom component; broker is ./mosquitto.nix.
      "mqtt"

      # Not used directly: ezviz_hp7 depends on it and only components listed
      # here get their python deps baked into the closure.
      "ffmpeg"
    ];

    customComponents = [
      pkgs.home-assistant-custom-components.localtuya # https://github.com/xZetsubou/hass-localtuya
      komfovent # https://github.com/lnagel/hass-komfovent
      ezviz-hp7 # https://github.com/Bobsilvio/ezviz_hp7
      pkgs.home-assistant-custom-components.frigate # https://github.com/blakeblackshear/frigate-hass-integration
    ];

    themes = with pkgs.home-assistant-themes; [
      material-you-theme # https://github.com/Nerwyn/material-you-theme
    ];

    # Rendered read-only into configuration.yaml; UI integrations live in .storage.
    config = {
      default_config = {};

      # No firewall on this host: the tailnet bind is what keeps HA off the LAN.
      http.server_host = "100.98.141.25";

      # `unique_id` puts it in the entity registry, so it can get an area in the UI.
      cover = [
        {
          platform = "group";
          name = "Žalúzie všetky";
          unique_id = "zaluzie_vsetky";
          entities = map (b: b.cover) blinds;
        }
      ];

      # `restore` keeps a running override across HA restarts.
      timer = lib.listToAttrs (map (c:
        lib.nameValuePair "${c.key}_manual" {
          name = "${c.label}: manuálny režim";
          duration = manualDurationOf c;
          restore = true;
        }) blinds) // {
        # See rekuManualDetector.
        rekuperacia_manual = {
          name = "Rekuperácia: manuálny režim";
          duration = "12:00:00";
          restore = true;
        };
      };

      # See rekuNightStart/rekuNightStop.
      input_boolean.rekuperacia_nocne_vetranie = {
        name = "Rekuperácia: nočné vetranie beží";
        icon = "mdi:weather-night";
      };

      # Split so the UI editor keeps working next to the declarative ones; HA merges labeled blocks.
      "automation ui" = "!include automations.yaml";
      "automation manual" = lib.concatMap (b: [
        (mkSunset b)
        (mkMorning b)
        (mkManualDetector b)
      ]) blinds
      ++ [
        rekuNightStart
        rekuNightStop
        rekuManualDetector
        rekuFilterNotify
        rekuFaultNotify
        zvoncekRingNotify
        zvoncekNotifyAction
        zavlahaRainSkip
        zavlahaStuck
      ];
      scene = "!include scenes.yaml";
      script = "!include scripts.yaml";
    };
  };

  # The ezviz_hp7 relay shells out to the ffmpeg binary; the "ffmpeg"
  # extraComponent only adds the python lib.
  systemd.services.home-assistant.path = [ pkgs.ffmpeg-headless ];

  # The module doesn't create `!include` targets and HA won't start without them.
  systemd.services.home-assistant.preStart = lib.mkAfter ''
    for f in automations.yaml scenes.yaml scripts.yaml; do
      [ -e "${config.services.home-assistant.configDir}/$f" ] || touch "${config.services.home-assistant.configDir}/$f"
    done
  '';
}
