{ config, lib, pkgs, ... }:

with lib;

let

  makeUpdateChannel = channelName: jobset:
    { timers."update-nixos-${channelName}" =
        { wantedBy = [ "timers.target" ];
          timerConfig.OnUnitInactiveSec = 600;
          timerConfig.OnBootSec = 900;
          timerConfig.AccuracySec = 300;
        };

      services."update-nixos-${channelName}" =
        { description = "Update Channel nixos-${channelName}";
          after = [ "networking.target" ];
          script =
            ''
              source /etc/profile
              rm -rf /data/releases/nixos/${channelName}/*-tmp || true
              cd /home/hydra-mirror/nixos-channel-scripts
              exec ./mirror-nixos-branch.pl ${channelName} ${jobset}
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
      [ (makeUpdateChannel "16.03" "release-16.03")
        (makeUpdateChannel "16.03-small" "release-16.03-small")
        (makeUpdateChannel "15.09" "release-15.09")
        (makeUpdateChannel "15.09-small" "release-15.09-small")
        (makeUpdateChannel "14.12" "release-14.12")
        (makeUpdateChannel "14.12-small" "release-14.12-small")
        (makeUpdateChannel "unstable" "trunk-combined")
        (makeUpdateChannel "unstable-small" "unstable-small")
      ];

}
