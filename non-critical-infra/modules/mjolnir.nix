{ lib, ... }:
{
  sops.secrets.mjolnir-password = {
    sopsFile = ../secrets/mjolnir-password.caliban;
    format = "binary";
    path = "/var/keys/mjolnir.password";
    mode = "0640";
    owner = "root";
    group = "mjolnir";
  };

  nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];

  # pantalaimon takes ages to start up, so mjolnir could hit the systemd burst
  # limit and then just be down forever. We don't want mjolnir to ever go down,
  # so disable rate-limiting and allow it to flap until pantalaimon is alive.
  systemd.services.mjolnir.serviceConfig.Restart = lib.mkForce "always";
  systemd.services.mjolnir.serviceConfig.RestartSec = 3;
  systemd.services.mjolnir.unitConfig.StartLimitIntervalSec = 0;

  services.pantalaimon-headless.instances.mjolnir.listenAddress = "::1";

  services.mjolnir = {
    enable = true;
    homeserverUrl = "https://matrix.nixos.org:443";

    pantalaimon = {
      enable = true;
      username = "mjolnir";
      passwordFile = "/var/keys/mjolnir.password";
      options = {
        listenAddress = "[::1]";
      };
    };

    managementRoom = "#mjolnir:nixos.org";

    # https://github.com/matrix-org/mjolnir/blob/master/config/default.yaml
    settings = {
      noop = false;
      protectAllJoinedRooms = true;
      fasterMembershipChecks = true;

      # too noisy
      verboseLogging = false;
    };
  };
}
