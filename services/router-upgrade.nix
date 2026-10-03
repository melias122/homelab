{ config, lib, pkgs, ... }:

# Switch live unless kernel/systemd/pppd changed (reexec or pppd restart = WAN outage); those wait for the weekly reboot.
let
  pppdUnits = map (n: "etc/systemd/system/pppd-${n}.service") (lib.attrNames config.services.pppd.peers);

  switchIfSafe = pkgs.writeShellScript "switch-if-safe" ''
    new=$(readlink -f /nix/var/nix/profiles/system)
    [ "$new" = "$(readlink -f /run/current-system)" ] && exit 0
    for p in kernel initrd kernel-modules; do
      [ "$(readlink -f /run/booted-system/$p)" = "$(readlink -f $new/$p)" ] || { echo "$p changed, waiting for reboot"; exit 0; }
    done
    for p in systemd ${toString pppdUnits}; do
      [ "$(readlink -f /run/current-system/$p)" = "$(readlink -f $new/$p)" ] || { echo "$p changed, waiting for reboot"; exit 0; }
    done
    exec $new/bin/switch-to-configuration switch
  '';
in
{
  system.autoUpgrade.operation = "boot";
  systemd.services.nixos-upgrade.serviceConfig.ExecStartPost = "${switchIfSafe}";

  # Reboot only if a staged generation is still pending.
  systemd.services.weekly-reboot = {
    startAt = "Wed 08:00";
    script = ''
      [ "$(readlink -f /nix/var/nix/profiles/system)" = "$(readlink -f /run/current-system)" ] || systemctl reboot
    '';
  };
}
