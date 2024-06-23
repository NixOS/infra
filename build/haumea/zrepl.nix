{ lib
, ...
}:

{
  programs.ssh = {
    knownHosts = {
      rsync-net = {
        hostNames = [ "zh2543b.rsync.net" "2001:1620:2019::324" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKlIcNwmx7id/XdYKZzVX2KtZQ4PAsEa9KVQ9N43L3PX";
      };
      hexa-backup-server = {
        hostNames = [ "meduna.hexa-home.v6.army" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUe5BqMDt562KOIcUm4RqZC5ejmd62elkYKkqExUYsl";
      };
    };
  };

  services.zrepl = let
    defaultBackupJob = {
      type = "push";
      filesystems."rpool/safe<" = true;
      snapshotting = {
        type = "periodic";
        interval = "1h";
        prefix = "zrepl_snap_";
        hooks = [ {
          # https://zrepl.github.io/master/configuration/snapshotting.html#postgres-checkpoint-hook
          type = "postgres-checkpoint";
          dsn = "host=/run/postgresql dbname=hydra user=root sslmode=disable";
          filesystems."rpool/safe/postgres" = true;
        } ];
      };
      pruning = {
        keep_sender = [
          { type = "not_replicated"; }
          {
            type = "grid";
            regex = "^zrepl_snap_.*";
            grid = lib.concatStringsSep " | " [
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
              # At this point we keep 9 snapshots spanning 8--16 days (depends on moment),
              # with exponentially increasing spacing (almost).
            ];
          }
        ];
        keep_receiver = [
          { type = "grid";
            regex = "^zrepl_snap_.*";
            grid = lib.concatStringsSep " | " [
              "1x1h"
              "1x2h"
              "1x4h"
              "2x8h"
              "7x1d"
              "52x1w"
            ];
          }
        ];
      };
    };
  in {
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
        # XXX: Broken since 2024-01-10?
        # (defaultBackupJob // {
        #   name = "rsyncnet";
        #   connect = {
        #     identity_file = "/root/.ssh/id_ed25519";
        #     type = "ssh+stdinserver";
        #     host = "zh2543b.rsync.net";
        #     user = "root";
        #     port = 22;
        #   };
        # })

        (defaultBackupJob // {
          name = "hexa";
          connect = {
            identity_file = "/root/.ssh/id_ed25519";
            type = "ssh+stdinserver";
            host = "meduna.hexa-home.v6.army";
            user = "zrepl";
            port = 22;
          };
        })
      ];
    };
  };
}
