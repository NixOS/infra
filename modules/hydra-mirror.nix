{ lib, pkgs, ... }:

let
  channels = (import ../channels.nix).channels-with-urls;

  orderLib = import ../lib/service-order.nix { inherit lib; };

  makeUpdateChannel = channelName: mainJob:
    {
      name = "update-${channelName}";
      value = {
        description = "Update Channel ${channelName}";
        path = [ pkgs.nixos-channel-scripts ];
        script =
          ''
            # FIXME: use IAM role.
            export AWS_ACCESS_KEY_ID=$(sed 's/aws_access_key_id=\(.*\)/\1/ ; t; d' ~/.aws/credentials)
            export AWS_SECRET_ACCESS_KEY=$(sed 's/aws_secret_access_key=\(.*\)/\1/ ; t; d' ~/.aws/credentials)
            exec mirror-nixos-branch ${channelName} https://hydra.nixos.org/job/${mainJob}/latest-finished
          '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = false;
          User = "hydra-mirror";
          # Allow the unit to use 80% of the system's RAM and 100% of the system's swap
          MemoryHigh = "80%";
        };
        unitConfig = {
          After = [ "networking.target" ];
        };
        environment.TMPDIR = "/scratch/hydra-mirror";
        environment.GC_INITIAL_HEAP_SIZE = "4g";
      };
    };

    updateJobs = orderLib.mkOrderedChain
      (lib.mapAttrsToList makeUpdateChannel channels);

in

{
  users.users.hydra-mirror =
    { description = "Channel mirroring user";
      home = "/home/hydra-mirror";
      openssh.authorizedKeys.keys = (import ../ssh-keys.nix).infra-core;
      uid = 497;
      group = "hydra-mirror";
    };

  users.groups.hydra-mirror = {};

  systemd.tmpfiles.rules = [
    ''
      F /scratch/hydra-mirror/nixos-files.sqlite - - - 8d
      e /scratch/hydra-mirror/release-*/*        - - - 1d -
    ''
  ];

  systemd.services = (lib.listToAttrs updateJobs) // {
    "update-all-channels" = {
      description = "Start all channel updates.";
      unitConfig = {
        After = builtins.map
          (service: "${service.name}.service")
          updateJobs;
        Wants = builtins.map
          (service: "${service.name}.service")
          updateJobs;
      };
      script = "true";
    };
  };

  systemd.timers."update-all-channels" = {
    description = "Start all channel updates.";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnUnitInactiveSec = 600;
      OnBootSec = 900;
      AccuracySec = 300;
    };
  };
}
