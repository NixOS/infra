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

  users.extraUsers.rfc39 = {
    description = "RFC39 Maintainer Team Sync";
    home = "/var/lib/rfc39-sync";
    createHome = true;
  };

  programs.ssh.knownHosts."github.com".publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==";

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
          git remote update origin
          git checkout main
          git reset --hard origin/main
          git gc

          nixpkgsdir=$HOME/nixpkgs
          if ! [[ -e $nixpkgsdir ]]; then
            git clone https://github.com/NixOS/nixpkgs.git $nixpkgsdir
          fi
          cd $nixpkgsdir
          git remote update origin
          git checkout origin/master
          git gc

          rfc39 \
              --dump-metrics --metrics-delay=240 --metrics-addr=0.0.0.0:9190 \
              --credentials /run/keys/rfc39-credentials.nix \
              --maintainers ./maintainers/maintainer-list.nix \
              sync-team NixOS 3345117 --limit 10 \
              --invited-list "$recordsdir/invitations"

          cd "$recordsdir"
          git add .
          git commit -m "Automated team sync results."
          git push origin main
        '';
    };

}
