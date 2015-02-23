{ config, pkgs, ... }:


{
  users.extraUsers.hydra-mirror =
    { description = "Hydra Mirrorer";
      home = "/home/hydra-mirror";
      isNormalUser = true;
      openssh.authorizedKeys.keys = with import ../ssh-keys.nix; [ eelco rob ];
    };

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

  /*
  systemd.services.generate-nixpkgs-patches =
    { description = "Generate Nixpkgs Patches";
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.su ];
      script =
        ''
          exec su - hydra-mirror -c 'cd nixos-channel-scripts; while true; do ./generate-linear-patch-sequence.sh; sleep 300; done'
        '';
      serviceConfig.Restart = "always";
      serviceConfig.CPUShares = 100;
    };
  */

  systemd.services.mirror-nixos-unstable =
    { description = "Mirror NixOS Unstable";
      wantedBy = [ "multi-user.target" ];
      after = [ "networking.target" ];
      path = [ pkgs.su ];
      script =
        ''
          rm -rf /data/releases/nixos/unstable/.tmp-*
          exec su - hydra-mirror -c 'cd nixos-channel-scripts; while true; do ./mirror-nixos-branch.sh unstable trunk-combined; sleep 1200; done'
        '';
      serviceConfig.Restart = "always";
      serviceConfig.CPUShares = 100;
    };

  systemd.services.mirror-nixos-unstable-small =
    { description = "Mirror NixOS Unstable-small";
      wantedBy = [ "multi-user.target" ];
      after = [ "networking.target" ];
      path = [ pkgs.su ];
      script =
        ''
          rm -rf /data/releases/nixos/unstable-small/.tmp-*
          exec su - hydra-mirror -c 'cd nixos-channel-scripts; while true; do ./mirror-nixos-branch.sh unstable-small unstable-small; sleep 1200; done'
        '';
      serviceConfig.Restart = "always";
      serviceConfig.CPUShares = 100;
    };

  systemd.services.mirror-nixos-14-04 =
    { description = "Mirror NixOS 14.04";
      wantedBy = [ "multi-user.target" ];
      after = [ "networking.target" ];
      path = [ pkgs.su ];
      script =
        ''
          rm -rf /data/releases/nixos/14.04/.tmp-*
          exec su - hydra-mirror -c 'cd nixos-channel-scripts; while true; do ./mirror-nixos-branch.sh 14.04 release-14.04; sleep 1200; done'
        '';
      serviceConfig.Restart = "always";
      serviceConfig.CPUShares = 100;
    };

  systemd.services.mirror-nixos-14-04-small =
    { description = "Mirror NixOS 14.04-small";
      wantedBy = [ "multi-user.target" ];
      after = [ "networking.target" ];
      path = [ pkgs.su ];
      script =
        ''
          rm -rf /data/releases/nixos/14.04-small/.tmp-*
          exec su - hydra-mirror -c 'cd nixos-channel-scripts; while true; do ./mirror-nixos-branch.sh 14.04-small release-14.04-small; sleep 900; done'
        '';
      serviceConfig.Restart = "always";
      serviceConfig.CPUShares = 100;
    };

  systemd.services.mirror-nixos-14-12 =
    { description = "Mirror NixOS 14.12";
      wantedBy = [ "multi-user.target" ];
      after = [ "networking.target" ];
      path = [ pkgs.su ];
      script =
        ''
          rm -rf /data/releases/nixos/14.12/.tmp-*
          exec su - hydra-mirror -c 'cd nixos-channel-scripts; while true; do ./mirror-nixos-stable.sh 14.12; sleep 1200; done'
        '';
      serviceConfig.Restart = "always";
      serviceConfig.CPUShares = 100;
    };

  systemd.services.mirror-nixos-14-12-small =
    { description = "Mirror NixOS 14.12-small";
      wantedBy = [ "multi-user.target" ];
      after = [ "networking.target" ];
      path = [ pkgs.su ];
      script =
        ''
          rm -rf /data/releases/nixos/14.12-small/.tmp-*
          exec su - hydra-mirror -c 'cd nixos-channel-scripts; while true; do ./mirror-nixos-branch.sh 14.12-small release-14.12-small; sleep 900; done'
        '';
      serviceConfig.Restart = "always";
      serviceConfig.CPUShares = 100;
    };

}
