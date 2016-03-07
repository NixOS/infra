{ config, lib, pkgs, ... }:

with lib;

let

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
          script =
            ''
              source /etc/profile
              cd /home/hydra-mirror/nixos-channel-scripts
              exec ./mirror-nixos-branch.pl ${channelName} http://hydra.nixos.org/job/${mainJob}/latest-finished \
                ${optionalString (channelName == "15.09") "1"}
            ''; # */
          serviceConfig.User = "hydra-mirror";
        };
    };

in

{
  environment.systemPackages =
    [ pkgs.wget
      pkgs.perlPackages.FileSlurp
      pkgs.perlPackages.LWP
      pkgs.perlPackages.LWPProtocolHttps
      pkgs.perlPackages.ListMoreUtils
    ];

  users.extraUsers.hydra-mirror =
    { description = "Channel mirroring user";
      home = "/home/hydra-mirror";
      isNormalUser = true;
      openssh.authorizedKeys.keys = with import ../ssh-keys.nix; [ eelco rob ];
      uid = 497;
    };

  /*
  systemd.services.mirror-nixpkgs =
    { description = "Mirror Nixpkgs";
      wantedBy = [ "multi-user.target" ];
      after = [ "networking.target" ];
      path = [ pkgs.su ];
      script =
        ''
          rm -rf /data/releases/nixpkgs/.tmp-*
          exec su - hydra-mirror -c 'cd nixos-channel-scripts; while true; do ./mirror-nixpkgs.sh; sleep 1200; done'
        '';
      serviceConfig.Restart = "always";
      serviceConfig.CPUShares = 100;
    };
  */

  systemd =
    fold recursiveUpdate {}
      [ (makeUpdateChannel "nixos-16.03" "nixos/release-16.03/tested")
        (makeUpdateChannel "nixos-16.03-small" "nixos/release-16.03-small/tested")
        (makeUpdateChannel "nixos-15.09" "nixos/release-15.09/tested")
        (makeUpdateChannel "nixos-15.09-small" "nixos/release-15.09-small/tested")
        (makeUpdateChannel "nixos-14.12" "nixos/release-14.12/tested")
        (makeUpdateChannel "nixos-14.12-small" "nixos/release-14.12-small/tested")
        (makeUpdateChannel "nixos-unstable" "nixos/trunk-combined/tested")
        (makeUpdateChannel "nixos-unstable-small" "nixos/unstable-small/tested")
        (makeUpdateChannel "nixpkgs-unstable" "nixpkgs/trunk/unstable")
      ];

}
