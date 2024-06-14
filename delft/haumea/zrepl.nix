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
        interval = "5m";
        prefix = "zrepl_snap_";
      };
      pruning = {
        keep_sender = [
          {
            type = "grid";
            regex = "^zrepl_snap_.*";
            grid = lib.concatStringsSep " | " [
              "4x15m"
              "24x1h"
              "4x1d"
              "3x1w"
            ];
          }
        ];
        keep_receiver = [
          { type = "grid";
            regex = "^zrepl_snap_.*";
            grid = lib.concatStringsSep " | " [
              "96x1h"
              "12x4h"
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
