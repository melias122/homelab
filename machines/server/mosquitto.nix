{ ... }:

{
  # The HA frigate integration requires MQTT for events (streams go over go2rtc).
  # Anonymous: no firewall on this host, the tailnet-only bind is the access
  # control, same as frigate's internal :5000 API.
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        address = "100.98.141.25";
        port = 1883;
        # Without the pattern ACL the default ACL denies anonymous clients everything.
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
        acl = [ "pattern readwrite #" ];
      }
    ];
  };

  # The tailscale IP must exist before the listener can bind (boot).
  systemd.services.mosquitto = {
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    serviceConfig.RestartSec = "5s";
  };
}
