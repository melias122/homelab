{ config, lib, pkgs, ... }:

# Switch live unless kernel/systemd/pppd changed (reexec or pppd restart = WAN outage); those wait for the weekly reboot.
# A generation that boots unhealthy is rolled back to the last one that booted healthy.
let
  cfg = config.upgrade;

  # GC root: nix-gc would otherwise delete the rollback target once it is 30 days old.
  good = "/nix/var/nix/gcroots/upgrade-good";
  bad = "/var/lib/upgrade/bad";

  pppdUnits = map (n: "etc/systemd/system/pppd-${n}.service") (lib.attrNames config.services.pppd.peers);

  switchIfSafe = pkgs.writeShellScript "switch-if-safe" ''
    new=$(readlink -f /nix/var/nix/profiles/system)
    [ "$new" = "$(readlink -f /run/current-system)" ] && exit 0
    # Fails nixos-upgrade so SystemdUnitFailed fires until the channel moves on.
    [ "$new" = "$(cat ${bad} 2>/dev/null)" ] && { echo "$new was rolled back, not activating"; exit 1; }
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
  options.upgrade = {
    rebootAt = lib.mkOption {
      type = lib.types.str;
      default = "Wed 08:00";
      description = "systemd calendar time of the weekly reboot.";
    };
    healthCheck = lib.mkOption {
      type = lib.types.str;
      description = "Shell condition that must hold within 10 minutes of booting a new generation.";
    };
  };

  config = {
    system.autoUpgrade.operation = "boot";
    systemd.services.nixos-upgrade.serviceConfig.ExecStartPost = "${switchIfSafe}";

    # Reboot only if a staged generation is still pending.
    systemd.services.weekly-reboot = {
      startAt = cfg.rebootAt;
      script = ''
        new=$(readlink -f /nix/var/nix/profiles/system)
        if [ "$new" = "$(cat ${bad} 2>/dev/null)" ]; then exit 0; fi
        pending=
        [ "$new" = "$(readlink -f /run/current-system)" ] || pending=1
        # A manual `switch` leaves profile == current with the old kernel still running.
        for p in kernel initrd kernel-modules; do
          [ "$(readlink -f /run/booted-system/$p)" = "$(readlink -f $new/$p)" ] || pending=1
        done
        if [ -n "$pending" ]; then systemctl reboot; fi
      '';
    };

    # Keyed on the booted generation, not on weekly-reboot: a power cut boots a staged one too.
    systemd.services.upgrade-health = {
      wantedBy = [ "multi-user.target" ];
      # Boot only; a live switch must never end in a reboot.
      restartIfChanged = false;
      path = [ config.nix.package ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "upgrade";
      };
      script = ''
        booted=$(readlink -f /run/booted-system)
        if [ "$booted" = "$(readlink -f ${good})" ]; then exit 0; fi
        for i in $(seq 60); do
          if
            ${cfg.healthCheck}
          then
            ln -sfn "$booted" ${good}
            exit 0
          fi
          sleep 10
        done
        if [ ! -e ${good} ]; then echo "unhealthy, no known-good generation to roll back to"; exit 1; fi
        prev=$(readlink -f ${good})
        echo "$booted unhealthy, rolling back to $prev"
        echo "$booted" > ${bad}
        # set -e: no reboot unless the bootloader really points at $prev again.
        nix-env -p /nix/var/nix/profiles/system --set "$prev"
        "$prev/bin/switch-to-configuration" boot
        systemctl reboot
      '';
    };
  };
}
