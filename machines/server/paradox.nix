{ config, pkgs, ... }:

let
  # PAI exec()s this as Python. PAI_* env vars override it, but only as str/int.
  paiConf = pkgs.writeText "pai.conf" ''
    # ESP32 serial↔TCP bridge on the panel's J4 (esphome/paradox.yaml), not an IP150.
    CONNECTION_TYPE = 'IP'
    IP_CONNECTION_HOST = '192.168.1.188'
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
    HOMEASSISTANT_PUBLISH_ZONE_PROPERTIES = ['open']
    # target/current_state are strings, as binary sensors they stay unknown;
    # the alarm panel entity already carries the state.
    HOMEASSISTANT_PUBLISH_PARTITION_PROPERTIES = []
  '';
in
{
  # Paradox SP5500+ → MQTT → HA discovery. PAI is not in nixpkgs.
  age.secrets.paradox-password.file = ../../secrets/paradox-password.age;

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

  # PAI's discovery skips troubles on Spectra panels (top-level status key, not
  # under 'system'); the state topic exists, so the aggregate is declared here.
  services.home-assistant.config.mqtt.binary_sensor = [
    {
      name = "Porucha ústredne";
      unique_id = "paradox_trouble";
      default_entity_id = "binary_sensor.alarm_dom_porucha";
      state_topic = "paradox/states/system/troubles/trouble";
      payload_on = "True";
      payload_off = "False";
      device_class = "problem";
      availability_topic = "paradox/interface/availability";
    }
  ];
}
