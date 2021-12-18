{ config, lib, pkgs, ... }:
let
  importer = pkgs.callPackage ../hydra-packet-importer { };
in
{
  deployment.keys."hydra-packet-import.json" = {
    keyFile = /home/deploy/src/nixos-org-configurations/hydra-packet-import.json;
    user = "hydra-packet";
  };

  users.users.hydra-packet = {
    description = "Hydra Packet Machine Importer";
    group = "hydra";
    isSystemUser = true;
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/hydra-packet-import 0755 hydra-packet hydra -"
    "f /var/lib/hydra-packet-import/machines 0644 hydra-packet hydra -"
  ];

  services.hydra-dev.buildMachinesFiles = [
    "/var/lib/hydra-packet-import/machines"
  ];

  systemd.services.hydra-packet-import = {
    path = with pkgs; [ openssh moreutils ];
    script = "${importer}/bin/hydra-packet-importer /run/keys/hydra-packet-import.json | sort | sponge /var/lib/hydra-packet-import/machines";
    serviceConfig = {
      User = "hydra-packet";
      Group = "keys";
      SupplementaryGroups = [ "hydra" "keys" ];
      Type = "oneshot";
      RuntimeMaxSec = 1800;
    };
  };

  systemd.timers.hydra-packet-import = {
    enable = true;
    description = "Update the list of Hydra machines from Packet.net";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/5";
    };
  };
}
