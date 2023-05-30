{ config, lib, ... }:
{
  deployment.keys = {
    "mjolnir.password" = {
      keyFile = /home/deploy/src/nixos-org-configurations/keys/mjolnir-password;
      user = config.systemd.services.mjolnir.serviceConfig.User;
      group = "keys";
      permissions = "0600";
    };
  };

  systemd.services.mjolnir.serviceConfig.SupplementaryGroups = [ "keys" ];
  # pantalaimon takes ages to start up, so mjolnir could hit the systemd burst
  # limit and then just be down forever. We don't want mjolnir to ever go down,
  # so disable rate-limiting and allow it to flap until pantalaimon is alive.
  systemd.services.mjolnir.serviceConfig.Restart = lib.mkForce "always";
  systemd.services.mjolnir.serviceConfig.RestartSec = 3;
  systemd.services.mjolnir.unitConfig.StartLimitIntervalSec = 0;

  services.pantalaimon-headless.instances.mjolnir.listenAddress = "::1";

  services.mjolnir = {
    enable = true;
    homeserverUrl = "https://nixos.ems.host:443";

    pantalaimon = {
      enable = true;
      username = "mjolnir";
      passwordFile = "/run/keys/mjolnir.password";
      options = {
        listenAddress = "[::1]";
      };
    };

    managementRoom = "#moderators:nixos.org";

    settings = {
      noop = false;
      protectAllJoinedRooms = true;
      fasterMembershipChecks = true;
    };
  };
}
