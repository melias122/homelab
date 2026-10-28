{ config, pkgs, ... }:

let
  # PAI exec()s this as Python. PAI_* env vars override it, but only as str/int.
  paiConf = pkgs.writeText "pai.conf" ''
    # ESP32 serial↔TCP bridge on the panel's J4 (esphome/paradox.yaml), not an IP150.
    CONNECTION_TYPE = 'IP'
    IP_CONNECTION_HOST = '10.30.0.2'
    IP_CONNECTION_PORT = 10000
    IP_CONNECTION_BARE = True

    # PC password = installer code; the panel stores digit 0 as nibble A.
    PASSWORD = open('/run/secrets/paradox-password').read().strip().replace('0', 'a')
    # The login packet carries the PC password.
    LOGGING_DUMP_PACKETS = False

    # The panel clock resets on every power cycle (timer_loss trouble).
    SYNC_TIME = True

    MQTT_ENABLE = True
    MQTT_HOST = '100.98.141.25'
    MQTT_HOMEASSISTANT_AUTODISCOVERY_ENABLE = True

    # power (vdc/battery/dc) reads garbage on this firmware; SYNC_TIME needs 'date'.
    LIMITS = {'system': ['date'], 'partition': [1], 'pgm': []}
    # Zone 'alarm' names the zone that tripped the alarm, entry_delay warns before
    # the siren. Not target/current_state: strings that stay unknown as binary
    # sensors, and the alarm panel entity already carries them.
    HOMEASSISTANT_PUBLISH_ZONE_PROPERTIES = ['open', 'alarm']
    HOMEASSISTANT_PUBLISH_PARTITION_PROPERTIES = ['entry_delay']
  '';

  # The aggregate covers every trouble; the others name the likely ones in the
  # notification, the rest are on the keypad (TRBL).
  troubles = [
    { key = "trouble"; id = "porucha"; name = "Porucha ústredne"; }
    { key = "ac_failure_trouble"; id = "porucha_siet"; name = "Výpadok siete"; }
    { key = "low_battery_trouble"; id = "porucha_bateria"; name = "Slabá batéria ústredne"; }
    { key = "bell_output_disconnected_trouble"; id = "porucha_sirena"; name = "Odpojená siréna"; }
  ];
in
{
  # Paradox SP5500+ → MQTT → HA discovery. PAI is not in nixpkgs.
  age.secrets.paradox-password.file = ../../secrets/paradox-password.age;

  # The ESP bridge shares VLAN 30 with nobody but the server (native on USPM16P
  # port 8, tagged to eno1 by the switches' default "auto" tagging): TCP 10000 has
  # no auth and PAI keeps the panel logged in, so any LAN client could disarm.
  networking.vlans.alarm = { id = 30; interface = "eno1"; };
  networking.interfaces.alarm.ipv4.addresses = [ { address = "10.30.0.1"; prefixLength = 30; } ];

  virtualisation.oci-containers.containers.paradox = {
    image = "docker.io/paradoxalarminterface/pai:3.7.0@sha256:8e9e94f38b841dded71cadfa02de929b0f8170b1b98ad837ad111cdcf3379e48";

    volumes = [
      "${paiConf}:/etc/pai/pai.conf:ro"
      "${config.age.secrets.paradox-password.path}:/run/secrets/paradox-password:ro"
    ];

    environment = {
      TZ = "Europe/Bratislava";
      # Image default 18839: with a fixed source port a restart can't reconnect
      # to mosquitto (same host) while the old connection sits in TIME_WAIT.
      PAI_MQTT_BIND_PORT = "0";
    };

    extraOptions = [ "--network=host" ];
  };

  systemd.services.podman-paradox = {
    after = [ "mosquitto.service" ];
    wants = [ "mosquitto.service" ];
  };

  # The house is only ever fully armed, and PAI can't do vacation/custom bypass;
  # PAI's discovery offers every mode, so the UI keeps just arm away (2) + disarm.
  services.home-assistant.config.homeassistant.customize."alarm_control_panel.alarm_dom".supported_features = 2;

  # PAI's discovery skips troubles on Spectra panels (top-level status key, not
  # under 'system'); the state topics exist, so they are declared here.
  services.home-assistant.config.mqtt.binary_sensor = map (t: {
    inherit (t) name;
    unique_id = "paradox_${t.key}";
    default_entity_id = "binary_sensor.alarm_dom_${t.id}";
    state_topic = "paradox/states/system/troubles/${t.key}";
    payload_on = "True";
    payload_off = "False";
    device_class = "problem";
    availability_topic = "paradox/interface/availability";
  }) troubles;

  # Any PIR in the last 30 min, armed or not (they pulse ~3 s per motion).
  services.home-assistant.config.template = [{
    binary_sensor = [{
      name = "Pohyb v dome";
      unique_id = "senzor_dom_pohyb";
      default_entity_id = "binary_sensor.senzor_dom_pohyb";
      device_class = "occupancy";
      state = ''
        {{ device_entities(device_id('alarm_control_panel.alarm_dom'))
           | select('match', 'binary_sensor[.]senzor_.*_pohyb$')
           | select('is_state', 'on') | list | count > 0 }}'';
      delay_off = "00:30:00";
    }];

    # Dashboard wrapper: arm in one tap, disarm only with the code. PAI's code
    # option would require it for arming too (the reminder notification arms).
    # HA checks the code; the panel never sees it.
    alarm_control_panel = [{
      name = "Alarm";
      unique_id = "alarm_dom_kod";
      default_entity_id = "alarm_control_panel.alarm_dom_kod";
      state = "{{ states('alarm_control_panel.alarm_dom') }}";
      availability = "{{ has_value('alarm_control_panel.alarm_dom') }}";
      code_arm_required = false;
      arm_away = [{ action = "alarm_control_panel.alarm_arm_away"; target.entity_id = "alarm_control_panel.alarm_dom"; }];
      disarm = [
        { variables.pin = "!secret alarm_kod"; }
        # A wrong code is silent; the card keeps showing armed. stop/error never reaches the UI.
        { condition = "template"; value_template = "{{ code | string == pin | string }}"; }
        { action = "alarm_control_panel.alarm_disarm"; target.entity_id = "alarm_control_panel.alarm_dom"; }
      ];
    }];
  }];

  # HA reads !secret values from secrets.yaml next to its config.
  age.secrets.hass-secrets = {
    file = ../../secrets/hass-secrets.age;
    owner = "hass";
  };
  systemd.tmpfiles.rules = [ "L+ /var/lib/hass/secrets.yaml - - - - ${config.age.secrets.hass-secrets.path}" ];
}
