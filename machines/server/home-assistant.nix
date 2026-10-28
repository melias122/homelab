{ config, lib, pkgs, ... }:

let
  # Close just before dark, morning tilt at max(civil dawn, `morningAt`): winter
  # dawns would open the blinds in the dark, summer ones at 04:00. A manual
  # move starts the blind's timer and the automations leave it alone while it
  # runs; the timer expires on its own, so a forgotten override can't disable
  # the automation for good.
  # Tilt works because all five Shellys have slat control calibrated.
  blinds = [
    # East window, morning sun on the desk and monitor: slats to 75 % once the
    # sun is up (50 % was too dark), raised for daylight when the direct sun no
    # longer gets in (~10:30 Oct–Dec, ~09:30 Mar–Jun).
    { key = "zaluzie_pracovna"; cover = "cover.zaluzia_pracovna"; label = "Žalúzie pracovňa"; shade = { tilt = 75; raiseAt = "10:30"; }; }
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
  # Sun elevations. Closing at sunset left it light outside (18:30 on
  # 2026-09-30); at -5° (18:56 that day) it's nearly dark and no light gets in.
  # Tilt from civil dawn, before that it's still dark.
  duskElevation = -5;
  dawnElevation = -6;
  # Jinja expression, zero-padded HH:MM: 06:30 Mon–Fri, 07:00 Sat/Sun.
  morningAt = "('07:00' if now().weekday() >= 5 else '06:30')";
  # Shade once the sun clears the horizon, cloudy or not: PV power is no sun
  # signal (zero export, it follows the house load) and forecasts missed.
  shadeElevation = 3;

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
  # Live view needs stream_source=local (integration options): the cloud stream
  # is unparseable on doorbell fw V5.4.x (https://github.com/Bobsilvio/ezviz_hp7/issues/51),
  # LAN works with video encryption off. relay_bind=127.0.0.1 because HA's
  # MJPEG/snapshot ffmpeg always dials tcp://127.0.0.1:<port>.
  # TODO(zvoncek frigate): patch stream_url to the bind host, then bind the
  # tailnet IP again and re-enable the camera in ./frigate-config.yml.
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
    # Drop once a release carries https://github.com/Bobsilvio/ezviz_hp7/pull/80.
    # The cloud now and then reports an old ring as the last alarm for one
    # poll and the alarm sensors pulsed on any *different* time, so the phone
    # got phantom "niekto zvoní" (2026-10-14 03:29, 2026-10-21 11:25).
    # Drop once a release carries https://github.com/Bobsilvio/ezviz_hp7/pull/81.
    # The relay's and HA's ffmpegs sat out their full 10 s analyzeduration, so
    # live view took ~11 s to start and snapshots brushed HA's 10 s timeout.
    # The same patch kills a snapshot ffmpeg whose request HA cancelled; a
    # leaked one hung the entry's unload (twice on 2026-10-26).
    patches = [
      ./ezviz-hp7-relogin.patch
      ./ezviz-hp7-alarm-newer.patch
      ./ezviz-hp7-analyzeduration.patch
    ];

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

  # EcoWater zmakcovac (192.168.1.91, Ayla module). No local API, the Ayla
  # cloud of the "EcoWater Wifi Manager" app is the only source. Hydrolink
  # Home accounts need ha-ecowater-hydrolink instead. No HACS on this host.
  ecowater-cloud = pkgs.buildHomeAssistantComponent rec {
    owner = "andrewtryder";
    domain = "ecowater_cloud";
    version = "0.7.3";

    src = pkgs.fetchFromGitHub {
      owner = "andrewtryder";
      repo = "ha-ecowater-cloud";
      tag = "v${version}";
      hash = "sha256-ZAj2Zk4pRsWxrSym+7m/G+lDpuoQBiQ3dvbhxLHpbZE=";
    };

    # Without a get_frequent_data write (the app does it on open) water today,
    # capacity and salt stay frozen in the cloud for days and the low-salt
    # alert never fires. Upstream left the force refresh out on purpose.
    patches = [ ./ecowater-cloud-frequent-data.patch ];

    meta = {
      description = "Home Assistant integration for EcoWater cloud-connected water softeners";
      homepage = "https://github.com/andrewtryder/ha-ecowater-cloud";
      license = pkgs.lib.licenses.mit;
    };
  };

  # Deye FVE striedac. Its DeyeCloud logger (192.168.1.87) has no local Modbus or
  # Solarman port, only an encrypted web UI, so without extra hardware the
  # official developer API is the only source; values are 3-5 min old. The
  # Energy dashboard now uses local Modbus (fotovoltika_* below); kept in parallel.
  # No HACS on this host.
  deye-cloud = pkgs.buildHomeAssistantComponent rec {
    owner = "maxbanton";
    domain = "deye_cloud";
    version = "1.5.3";

    src = pkgs.fetchFromGitHub {
      owner = "maxbanton";
      repo = "hass-deye-cloud";
      tag = "v${version}";
      hash = "sha256-HYnVpZ0oyyZKrkUggOZMAu/+KRSLiO5k8266oz9KgVs=";
    };

    meta = {
      description = "Home Assistant integration for Deye inverters via the Deye Cloud API";
      homepage = "https://github.com/maxbanton/hass-deye-cloud";
      license = pkgs.lib.licenses.mit;
    };
  };

  # Deye registers as in ./deye-modbus.yml. HA derives the entity_id from the name,
  # so `id` must match its slug.
  fvePower = id: name: address: data_type: {
    inherit name address data_type;
    unique_id = "fotovoltika_${id}";
    device_address = 1;
    unit_of_measurement = "W";
    device_class = "power";
    state_class = "measurement";
    scan_interval = 30;
  };
  fveEnergy = id: name: address: {
    inherit name address;
    unique_id = "fotovoltika_${id}";
    device_address = 1;
    data_type = "uint32";
    swap = "word"; # low word first
    scale = 0.1;
    precision = 1;
    unit_of_measurement = "kWh";
    device_class = "energy";
    state_class = "total_increasing";
    scan_interval = 60;
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
               | selectattr('attributes.id', 'in', ['${c.key}_zapad', '${c.key}_vychod', '${c.key}_tienenie_slnko', '${c.key}_tienenie_koniec'])
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
    alias = "${b.label}: dole po zotmení";
    triggers = [
      { trigger = "numeric_state"; entity_id = "sun.sun"; attribute = "elevation"; below = duskElevation; }
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
      { trigger = "numeric_state"; entity_id = "sun.sun"; attribute = "elevation"; above = dawnElevation; }
      { trigger = "template"; value_template = "{{ now().strftime('%H:%M') == ${morningAt} }}"; }
    ];
    conditions = lib.optional (!(b.morningIgnoresManual or false)) (manualIdle b)
    ++ [
      # String compare; `>=` lets the exact-time trigger pass.
      {
        condition = "template";
        value_template = "{{ now().strftime('%H:%M') >= ${morningAt} }}";
      }
      {
        condition = "numeric_state";
        entity_id = "sun.sun";
        attribute = "elevation";
        above = dawnElevation;
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

  mkShadeSun = b: {
    id = "${b.key}_tienenie_slnko";
    alias = "${b.label}: po východe slnka privrieť lamely na ${toString b.shade.tilt} %";
    triggers = [
      { trigger = "numeric_state"; entity_id = "sun.sun"; attribute = "elevation"; above = shadeElevation; }
      # Sampling: in summer the sun is already up when the morning tilt runs.
      { trigger = "time_pattern"; minutes = "/5"; }
    ];
    conditions = [
      (manualIdle b)
      { condition = "time"; before = "${b.shade.raiseAt}:00"; }
      { condition = "numeric_state"; entity_id = "sun.sun"; attribute = "elevation"; above = shadeElevation; }
      # Only from open slats, so the sampling doesn't re-tilt every 5 min
      # (each move closes the slats fully first). A set to 50 reads back as 51.
      {
        condition = "numeric_state";
        entity_id = b.cover;
        attribute = "current_tilt_position";
        above = b.shade.tilt + 10;
      }
      # Lowered blind only, see mkMorning.
      {
        condition = "numeric_state";
        entity_id = b.cover;
        attribute = "current_position";
        below = 5;
      }
    ];
    actions = [
      {
        action = "cover.set_cover_tilt_position";
        target.entity_id = b.cover;
        data.tilt_position = b.shade.tilt;
      }
    ];
  };

  # Every day, shaded or not: the sunset close still lowers it.
  mkShadeEnd = b: {
    id = "${b.key}_tienenie_koniec";
    alias = "${b.label}: o ${b.shade.raiseAt} vytiahnuť hore";
    triggers = [ { trigger = "time"; at = "${b.shade.raiseAt}:00"; } ];
    conditions = [ (manualIdle b) ];
    actions = [
      { action = "cover.open_cover"; target.entity_id = b.cover; }
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
      # Winter Intensive is 25 °C (rekuSeasonApply), a flush would just recover heat.
      { condition = "state"; entity_id = "input_boolean.rekuperacia_zimny_rezim"; state = "off"; }
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

  # Heating season: Normal 23.5 equals the HP room setpoint, so ECO free cooling
  # (outdoor within ECO min–max, 10–26 °C) would vent heat the HP just made.
  # 3-day mean (house and floor heating are slow) sampled daily; the HP still
  # did not heat at a 3-day mean of 14 °C (Sep 2026), hence 12.
  rekuSeason = {
    id = "rekuperacia_sezona_prepnut";
    alias = "Rekuperácia: zimný režim podľa vonkajšej teploty";
    triggers = [ { trigger = "time"; at = "12:00:00"; } ];
    actions = [
      {
        choose = [
          {
            conditions = [ { condition = "numeric_state"; entity_id = "sensor.rekuperacia_vonkajsia_teplota_3d"; below = 12; } ];
            sequence = [ { action = "input_boolean.turn_on"; target.entity_id = "input_boolean.rekuperacia_zimny_rezim"; } ];
          }
          {
            conditions = [ { condition = "numeric_state"; entity_id = "sensor.rekuperacia_vonkajsia_teplota_3d"; above = 18; } ];
            sequence = [ { action = "input_boolean.turn_off"; target.entity_id = "input_boolean.rekuperacia_zimny_rezim"; } ];
          }
        ];
      }
    ];
  };

  # Driven by the flag, so flipping it by hand in the UI applies too.
  rekuSeasonApply = {
    id = "rekuperacia_sezona_nastavit";
    alias = "Rekuperácia: použiť zimné/letné teploty";
    mode = "restart";
    triggers = [
      # from/to: the restore at HA start must not rewrite the unit.
      { trigger = "state"; entity_id = "input_boolean.rekuperacia_zimny_rezim"; from = [ "on" "off" ]; to = [ "on" "off" ]; }
    ];
    actions = [
      # Nothing retries a write lost in a ~30 s Modbus dropout.
      {
        wait_template = "{{ states('climate.rekuperacia') not in ['unavailable', 'unknown'] }}";
        timeout = "00:10:00";
        continue_on_timeout = false;
      }
      { variables.zima = "{{ is_state('input_boolean.rekuperacia_zimny_rezim', 'on') }}"; }
      { action = "number.set_value"; target.entity_id = "number.rekuperacia_normal_temperature"; data.value = "{{ 25 if zima else 23.5 }}"; }
      { action = "number.set_value"; target.entity_id = "number.rekuperacia_override_temperature"; data.value = "{{ 25 if zima else 23 }}"; }
      # Summer 10 °C = rekuNightStart flush; in winter a manual Intensive would blow ~10 °C air.
      { action = "number.set_value"; target.entity_id = "number.rekuperacia_intensive_temperature"; data.value = "{{ 25 if zima else 10 }}"; }
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

  # Critical alert: rings through silent mode and Focus. Lists the alarm's
  # zones still open; the one that tripped may have closed again already.
  alarmPhones = [ "notify.mobile_app_iphone_16_m" "notify.mobile_app_lulu" ];

  alarmTriggeredNotify = {
    id = "alarm_notifikacia_poplach";
    alias = "Alarm: notifikácia — poplach";
    mode = "single";
    triggers = [
      { trigger = "state"; entity_id = "alarm_control_panel.alarm_dom"; to = "triggered"; }
    ];
    actions = map (svc: {
      action = svc;
      data = {
        title = "Alarm: POPLACH";
        message = ''
          {%- set z = device_entities(device_id('alarm_control_panel.alarm_dom'))
             | select('match', 'binary_sensor') | select('is_state', 'on')
             | map('state_attr', 'friendly_name') | list -%}
          {{ 'Otvorené: ' ~ z | join(', ') if z else 'Žiadna zóna už nie je otvorená.' }}'';
        data = {
          tag = "alarm";
          push = {
            sound = { name = "default"; critical = 1; volume = 1.0; };
            interruption-level = "critical";
          };
        };
      };
    }) alarmPhones;
  };

  # timer_loss after a power cycle clears within seconds (PAI SYNC_TIME).
  alarmFaultNotify = {
    id = "alarm_notifikacia_porucha";
    alias = "Alarm: notifikácia — porucha ústredne";
    triggers = [
      { trigger = "state"; entity_id = "binary_sensor.alarm_dom_porucha"; to = "on"; "for" = "00:05:00"; }
    ];
    actions = [
      {
        action = "notify.mobile_app_iphone_16_m";
        data = {
          title = "Alarm: porucha";
          message = "Ústredňa hlási poruchu, detail na klávesnici (TRBL).";
        };
      }
    ];
  };

  # Unavailable = PAI died (MQTT will), PAI lost the panel or the ESP bridge
  # (it reports offline itself), or HA lost mosquitto.
  alarmOfflineNotify = {
    id = "alarm_notifikacia_vypadok";
    alias = "Alarm: notifikácia — výpadok spojenia s ústredňou";
    triggers = [
      { trigger = "state"; entity_id = "alarm_control_panel.alarm_dom"; to = "unavailable"; "for" = "00:05:00"; }
    ];
    actions = [
      {
        action = "notify.mobile_app_iphone_16_m";
        data = {
          title = "Alarm: výpadok";
          message = "HA 5 min nevidí ústredňu (PAI, ESP most alebo MQTT). Ústredňa stráži ďalej, len bez HA.";
        };
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

  # With nobody home the runs only cool the loop. The schedule stays on the
  # Shelly (shelly/cerpadlo-tuv-schedule.sh), HA cuts each run within a second;
  # the off also cancels the run's toggle_after. A dead HA runs the pump as before.
  tuvNiktoDoma = {
    id = "obehove_cerpadlo_tuv_nikto_doma";
    alias = "Obehové čerpadlo TÚV: nebeží, keď nikto nie je doma";
    triggers = [
      { trigger = "state"; entity_id = "switch.zasuvka_technicka_obehove_cerpadlo_tuv"; to = "on"; }
    ];
    conditions = [
      # All listed must match, and an unknown phone isn't not_home, so it lets
      # the pump run. zone.home's count would read unknown as away.
      { condition = "state"; entity_id = [ "person.641" "person.lulu" ]; state = "not_home"; }
    ];
    actions = [
      { action = "switch.turn_off"; target.entity_id = "switch.zasuvka_technicka_obehove_cerpadlo_tuv"; }
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
      # /api/prometheus, scraped by ./monitoring.nix.
      "prometheus"

      "gree"
      "shelly"
      "hue"
      # Shelly BLU H&T in the detska prizemie. No BT adapter on this host: its adverts
      # come in through the BLE scanner on the detska 2PM (Shelly entry option).
      "bthome"
      # WiFi presence for person.*, works even when the phone app reports no
      # location. Controller is on this host (./unifi.nix), config flow to localhost:8443.
      "unifi"

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
      ecowater-cloud # https://github.com/andrewtryder/ha-ecowater-cloud
      deye-cloud # https://github.com/maxbanton/hass-deye-cloud
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

      # Only what Grafana shows: the TUV circulation pump and its return-pipe probe
      # (schedule on the Shelly, shelly/cerpadlo-tuv-schedule.sh) and the
      # Komfovent, whose only Modbus client stays HA, the cloud-only zmakcovac
      # and FVE (deye_cloud), and the room temps (floor heating balance).
      prometheus.filter.include_entities = [
        "switch.zasuvka_technicka_obehove_cerpadlo_tuv"
        "sensor.zasuvka_technicka_obehove_cerpadlo_tuv_vykon"
        "sensor.senzor_technicka_spiatocka_tuv_teplota"
        "input_boolean.rekuperacia_zimny_rezim"
        # Hue motion sensor moved to the WC: candidate spot for the heat pump room probe.
        "sensor.schody_teplota"
        "sensor.senzor_detska_prizemie_teplota"
        "sensor.senzor_detska_prizemie_vlhkost"
      ];
      prometheus.filter.include_entity_globs = [
        "sensor.rekuperacia_*"
        "binary_sensor.rekuperacia_*"
        "sensor.zmakcovac_*"
        "binary_sensor.zmakcovac_*"
        "sensor.fve_*"
        "climate.klima_*"
      ];

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

      # See rekuSeason/rekuSeasonApply.
      input_boolean.rekuperacia_zimny_rezim = {
        name = "Rekuperácia: zimný režim";
        icon = "mdi:snowflake";
      };

      # rekuperacia_ prefix: picked up by the prometheus glob above.
      sensor = [
        {
          platform = "statistics";
          name = "Rekuperácia vonkajšia teplota 3d";
          unique_id = "rekuperacia_vonkajsia_teplota_3d";
          entity_id = "sensor.rekuperacia_outdoor_temperature";
          # Time-weighted: the sensor only reports changes.
          state_characteristic = "average_step";
          max_age.days = 3;
        }
      ];

      # FVE via the Waveshare RS485 gateway, which Prometheus polls too (multi-host).
      # Sensors only: nothing here writes inverter registers. Grid + = import and battery
      # + = discharge, as the Energy dashboard expects. Not in the prometheus globs: deye_* has it all.
      modbus = [{
        name = "fotovoltika";
        type = "tcp";
        host = "192.168.1.88";
        port = 502;
        sensors = [
          (fvePower "vykon_pv1" "Fotovoltika výkon PV1" 672 "uint16")
          (fvePower "vykon_pv2" "Fotovoltika výkon PV2" 673 "uint16")
          (fvePower "vykon_siet" "Fotovoltika výkon sieť" 625 "int16")
          (fvePower "vykon_spotreba" "Fotovoltika výkon spotreba" 653 "int16")
          (fveEnergy "energia_vyroba" "Fotovoltika energia výroba" 534)
          (fveEnergy "energia_odber" "Fotovoltika energia odber" 522)
          (fveEnergy "energia_dodavka" "Fotovoltika energia dodávka" 524)
          (fveEnergy "energia_spotreba" "Fotovoltika energia spotreba" 527)
          (fvePower "vykon_bateria" "Fotovoltika výkon batéria" 590 "int16")
          (fveEnergy "energia_nabijanie" "Fotovoltika energia nabíjanie" 516)
          (fveEnergy "energia_vybijanie" "Fotovoltika energia vybíjanie" 518)
          {
            name = "Fotovoltika batéria";
            unique_id = "fotovoltika_bateria";
            address = 588;
            device_address = 1;
            data_type = "uint16";
            unit_of_measurement = "%";
            device_class = "battery";
            state_class = "measurement";
            scan_interval = 60;
          }
        ];
      }];

      # The Energy dashboard takes one solar power sensor.
      template = [{
        sensor = [{
          name = "Fotovoltika výkon výroba";
          unique_id = "fotovoltika_vykon_vyroba";
          unit_of_measurement = "W";
          device_class = "power";
          state_class = "measurement";
          state = "{{ states('sensor.fotovoltika_vykon_pv1') | float(0) + states('sensor.fotovoltika_vykon_pv2') | float(0) }}";
          availability = "{{ has_value('sensor.fotovoltika_vykon_pv1') and has_value('sensor.fotovoltika_vykon_pv2') }}";
        }];
      }];

      # Split so the UI editor keeps working next to the declarative ones; HA merges labeled blocks.
      "automation ui" = "!include automations.yaml";
      "automation manual" = lib.concatMap (b: [
        (mkSunset b)
        (mkMorning b)
        (mkManualDetector b)
      ] ++ lib.optionals (b ? shade) [ (mkShadeSun b) (mkShadeEnd b) ]) blinds
      ++ [
        rekuNightStart
        rekuNightStop
        rekuManualDetector
        rekuSeason
        rekuSeasonApply
        rekuFilterNotify
        rekuFaultNotify
        zvoncekRingNotify
        zvoncekNotifyAction
        alarmTriggeredNotify
        alarmFaultNotify
        alarmOfflineNotify
        zavlahaRainSkip
        zavlahaStuck
        tuvNiktoDoma
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
