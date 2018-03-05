{ config, lib, pkgs, ... }:

with lib;

let

  channelScripts = import <nixos-channel-scripts> { inherit pkgs; };

  makeUpdateChannel = channelName: mainJob:
    { timers."update-${channelName}" =
        { wantedBy = [ "timers.target" ];
          timerConfig.OnUnitInactiveSec = 600;
          timerConfig.OnBootSec = 900;
          timerConfig.AccuracySec = 300;
        };

      services."update-${channelName}" =
        { description = "Update Channel ${channelName}";
          after = [ "networking.target" ];
          path = [ channelScripts ];
          script =
            ''
              # FIXME: use IAM role.
              export AWS_ACCESS_KEY_ID=$(sed 's/aws_access_key_id=\(.*\)/\1/ ; t; d' ~/.aws/credentials)
              export AWS_SECRET_ACCESS_KEY=$(sed 's/aws_secret_access_key=\(.*\)/\1/ ; t; d' ~/.aws/credentials)
              exec mirror-nixos-branch ${channelName} https://hydra.nixos.org/job/${mainJob}/latest-finished
            ''; # */
          serviceConfig.User = "hydra-mirror";
        };
    };

in

{
  users.extraUsers.hydra-mirror =
    { description = "Channel mirroring user";
      home = "/home/hydra-mirror";
      isNormalUser = true;
      openssh.authorizedKeys.keys = with import ../ssh-keys.nix; [ eelco rob ];
      uid = 497;
    };

  systemd =
    fold recursiveUpdate {} [
      (makeUpdateChannel "nixos-18.03" "nixos/release-18.03/tested")
      (makeUpdateChannel "nixos-18.03-small" "nixos/release-18.03-small/tested")
      (makeUpdateChannel "nixos-17.09" "nixos/release-17.09/tested")
      (makeUpdateChannel "nixos-17.09-small" "nixos/release-17.09-small/tested")
      (makeUpdateChannel "nixos-17.03" "nixos/release-17.03/tested")
      (makeUpdateChannel "nixos-17.03-small" "nixos/release-17.03-small/tested")
      (makeUpdateChannel "nixos-16.09" "nixos/release-16.09/tested")
      (makeUpdateChannel "nixos-16.09-small" "nixos/release-16.09-small/tested")
      (makeUpdateChannel "nixos-unstable" "nixos/trunk-combined/tested")
      (makeUpdateChannel "nixos-unstable-small" "nixos/unstable-small/tested")
      (makeUpdateChannel "nixpkgs-18.03-darwin" "nixpkgs/nixpkgs-18.03-darwin/darwin-tested")
      (makeUpdateChannel "nixpkgs-17.09-darwin" "nixpkgs/nixpkgs-17.09-darwin/darwin-tested")
      (makeUpdateChannel "nixpkgs-unstable" "nixpkgs/trunk/unstable")
    ];

}
