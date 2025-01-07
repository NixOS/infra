{ lib, ... }:

{
  programs.ssh = {
    knownHosts = {
      rsync-net = {
        hostNames = [
          "zh2543b.rsync.net"
          "2001:1620:2019::324"
        ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKlIcNwmx7id/XdYKZzVX2KtZQ4PAsEa9KVQ9N43L3PX";
      };
    };
  };

  services.zrepl =
    let
      defaultBackupJob = {
        type = "push";
        filesystems."rpool/safe<" = true;
        snapshotting = {
          type = "periodic";
          interval = "30m";
          prefix = "zrepl_snap_";
          hooks = [
            {
              # https://zrepl.github.io/master/configuration/snapshotting.html#postgres-checkpoint-hook
              type = "postgres-checkpoint";
              dsn = "host=/run/postgresql dbname=hydra user=root sslmode=disable";
              filesystems."rpool/safe/postgres" = true;
            }
          ];
        };

        # The current pruning setup is an exponentially growing scheme, at both sides.
        pruning = {
          keep_sender = [
            { type = "not_replicated"; }
            {
              type = "grid";
              regex = "^zrepl_snap_.*";
              grid = lib.concatStringsSep " | " [
                "1x1h(keep=all)"
                "1x1h"
                "1x2h"
                "1x4h"
                # "grid" acts weird if an interval isn't a whole-number multiple
                # of the previous one, so we jump from 8h to 24h
                "2x8h"
                "1x1d"
                "1x2d"
                "1x4d"
                "1x8d"
                # At this point we keep ~10 snapshots spanning 8--16 days (depends on moment),
                # with exponentially increasing spacing (almost).
              ];
            }
          ];
          keep_receiver = [
            {
              type = "grid";
              regex = "^zrepl_snap_.*";
              grid = lib.concatStringsSep " | " [
                "2x1h(keep=all)"
                "2x1h"
                "2x2h"
                "2x4h"
                "4x8h"
                # At this point the grid spans 2 days by ~13 snapshots.
                # (See note above about 8h -> 24h.)
                "2x1d"
                "2x2d"
                "2x4d"
                "2x8d"
                "2x16d"
                "2x32d"
                "2x64d"
                "2x128d"
                # At this point we keep ~29 snapshots spanning 384--512 days (depends on moment),
                # with exponentially increasing spacing (almost).
              ];
            }
          ];
        };
      };
    in
    {
      enable = true;
      settings = {
        global = {
          logging = [
            {
              type = "syslog";
              level = "info";
              format = "human";
            }
          ];
        };

        jobs = [
          # Covers 20240629+
          (
            defaultBackupJob
            // {
              name = "rsyncnet";
              connect = {
                identity_file = "/root/.ssh/id_ed25519";
                type = "ssh+stdinserver";
                host = "zh4461b.rsync.net";
                user = "root";
                port = 22;
              };
            }
          )
          /*
            rsync.net provides a VM with FreeBSD
            - almost nothing is preserved on upgrades except this "data1" zpool
             $ scp ./zrepl.yml root@zh4461b.rsync.net:/usr/local/etc/zrepl/zrepl.yml
             # pkg install zrepl
             # service zrepl enable
             # service zrepl start
          */
        ];
      };
    };
}
