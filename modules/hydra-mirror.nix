{ lib, pkgs, ... }:

let
  channels = {
      # Channel name           https://hydra.nixos.org/job/<value>/latest-finished
      "nixos-unstable"       = "nixos/trunk-combined/tested";
      "nixos-unstable-small" = "nixos/unstable-small/tested";
      "nixpkgs-unstable"     = "nixpkgs/trunk/unstable";

      "nixos-19.03"          = "nixos/release-19.03/tested";
      "nixos-19.03-small"    = "nixos/release-19.03-small/tested";
      "nixpkgs-19.03-darwin" = "nixpkgs/nixpkgs-19.03-darwin/darwin-tested";

      "nixos-18.09"          = "nixos/release-18.09/tested";
      "nixos-18.09-small"    = "nixos/release-18.09-small/tested";
      "nixpkgs-18.09-darwin" = "nixpkgs/nixpkgs-18.09-darwin/darwin-tested";

      "nixos-18.03"          = "nixos/release-18.03/tested";
      "nixos-18.03-small"    = "nixos/release-18.03-small/tested";
      "nixpkgs-18.03-darwin" = "nixpkgs/nixpkgs-18.03-darwin/darwin-tested";
  };

  channelScripts = import <nixos-channel-scripts> { inherit pkgs; };
  orderLib = import ../lib/service-order.nix { inherit lib; };

  makeUpdateChannel = channelName: mainJob:
    {
      name = "update-${channelName}";
      value = {
        description = "Update Channel ${channelName}";
        path = [ channelScripts ];
        script =
          ''
            # FIXME: use IAM role.
            export AWS_ACCESS_KEY_ID=$(sed 's/aws_access_key_id=\(.*\)/\1/ ; t; d' ~/.aws/credentials)
            export AWS_SECRET_ACCESS_KEY=$(sed 's/aws_secret_access_key=\(.*\)/\1/ ; t; d' ~/.aws/credentials)
            exec mirror-nixos-branch ${channelName} https://hydra.nixos.org/job/${mainJob}/latest-finished
          '';
        serviceConfig.User = "hydra-mirror";
        unitConfig.After = [ "networking.target" ];
        environment.TMPDIR = "/scratch/hydra-mirror";
        environment.GC_INITIAL_HEAP_SIZE = "4g";
        };
    };

    updateJobs = orderLib.mkOrderedChain
      (lib.mapAttrsToList makeUpdateChannel channels);

in

{
  imports = [ ./hydra-mirror-user.nix ];

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
