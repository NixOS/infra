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

  deployment.keys."rfc39-record-push.key" = {
    keyFile = /home/deploy/src/nixos-org-configurations/keys/rfc39-record-push.key;
    user = "rfc39";
  };

  users.users.rfc39 = {
    description = "RFC39 Maintainer Team Sync";
    home = "/var/lib/rfc39-sync";
    createHome = true;
    isSystemUser = true;
    group = "rfc39";
  };
  users.groups.rfc39 = {};


  programs.ssh.knownHosts."github.com".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

  systemd.services.rfc39-sync = {
    description = "Sync the Maintainer Team ";
    path  = [ config.nix.package pkgs.git pkgs.openssh rfc39 ];
    startAt = "*:0/30";
    serviceConfig.User = "rfc39";
    serviceConfig.Group = "keys";
    serviceConfig.Type = "oneshot";
    serviceConfig.PrivateTmp = true;
    script =
        ''
          set -eux

          export GIT_SSH_COMMAND='ssh -i /run/keys/rfc39-record-push.key'
          export GIT_AUTHOR_NAME="rfc39"
          export GIT_AUTHOR_EMAIL="rfc39@eris"
          export GIT_COMMITTER_NAME="rfc39"
          export GIT_COMMITTER_EMAIL="rfc39@eris"

          recordsdir=$HOME/rfc39-record
          if ! [[ -e "$recordsdir" ]]; then
            git clone git@github.com:NixOS/rfc39-record.git "$recordsdir"
          fi
          cd "$recordsdir"
          git fetch origin --no-auto-maintenance
          git checkout main
          git reset --hard origin/main
          git maintenance run --auto

          nixpkgsdir=$HOME/nixpkgs
          if ! [[ -e $nixpkgsdir ]]; then
            git clone https://github.com/NixOS/nixpkgs.git $nixpkgsdir
          fi
          cd $nixpkgsdir
          git fetch origin --no-auto-maintenance
          git checkout origin/master
          git maintenance run --auto

          rfc39 \
              --dump-metrics --metrics-delay=240 --metrics-addr=0.0.0.0:9190 \
              --credentials /run/keys/rfc39-credentials.nix \
              --maintainers ./maintainers/maintainer-list.nix \
              sync-team NixOS 3345117 --limit 50 \
              --invited-list "$recordsdir/invitations"

          cd "$recordsdir"

          if ! git diff --quiet; then
            git add .
            git commit -m "Automated team sync results."
            git push origin main
          fi
        '';
    };

}
