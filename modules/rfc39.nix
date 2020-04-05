# This module fetches nixpkgs master and syncs the GitHub maintainer team.
{ config, pkgs, ... }:
let
  rfc39 = import /home/deploy/src/rfc39 { inherit pkgs; };
in {
  deployment.keys."rfc39-credentials.nix" = {
    keyFile = /home/deploy/src/nixos-org-configurations/keys/rfc39-credentials.nix;
    user = "rfc39";
  };

  deployment.keys."rfc39-github.der" = {
    keyFile = /home/deploy/src/nixos-org-configurations/keys/rfc39-github.der;
    user = "rfc39";
  };


  users.extraUsers.rfc39 = {
    description = "RFC39 Maintainer Team Sync";
    home = "/var/lib/rfc39-sync";
    createHome = true;
  };

  systemd.services.rfc39-sync = {
    enable = false;
    description = "Sync the Maintainer Team ";
    path  = [ config.nix.package pkgs.git rfc39 ];
    startAt = "*:0/30";
    serviceConfig.User = "rfc39";
    serviceConfig.Group = "keys";
    serviceConfig.Type = "oneshot";
    serviceConfig.PrivateTmp = true;
    script =
        ''
          set -eux

          dir=$HOME/nixpkgs
          if ! [[ -e $dir ]]; then
            git clone https://github.com/NixOS/nixpkgs.git $dir
          fi
          cd $dir
          git remote update origin
          git checkout origin/master
          git gc

          exec rfc39 \
              --dump-metrics --metrics-delay=240 --metrics-addr=0.0.0.0:9190 \
              --credentials /run/keys/rfc39-credentials.nix \
              --maintainers ./maintainers/maintainer-list.nix \
              sync-team NixOS 3345117 --limit 10
        '';
    };

}
