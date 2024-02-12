{ config, lib, pkgs, ...}:

{
  imports =
    [ ./common.nix
      # ./datadog.nix # error: psycopg2-2.9.1 not supported for interpreter python2.7
      ./fstrim.nix
      ./haumea/network.nix
    ];

  system.stateVersion = "14.12";
  environment.systemPackages = [ pkgs.lz4 ];

  users.users.root.openssh.authorizedKeys.keys =
    with import ../ssh-keys.nix; infra-core;

  fileSystems."/" =
    { device = "rpool/safe/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/boot0";
      fsType = "ext4";
    };

  fileSystems."/nix" =
    { device = "rpool/local/nix";
      fsType = "zfs";
    };

  fileSystems."/var/db/postgresql" =
    { device = "rpool/safe/postgres";
      fsType = "zfs";
    };

  networking.hostId = "83c81a23";

  boot.loader.grub.devices = [ "/dev/nvme0n1" "/dev/nvme1n1" ];
  boot.loader.grub.copyKernels = true;

  systemd.services.postgresql = {
    after = [ "wireguard-wg0.service" ];
    requires = [ "wireguard-wg0.service" ];
  };
  services.postgresql = {
    enable = true;
    package = if true then pkgs.postgresql_14 else pkgs.postgresql_14.overrideAttrs({ nativeBuildInputs, configureFlags, ...}: {
      # Enable JIT compilation of queries, remove after https://github.com/NixOS/nixpkgs/pull/124804
      nativeBuildInputs = nativeBuildInputs ++ [ pkgs.llvm pkgs.clang ];
      configureFlags = configureFlags ++ [ "--with-llvm" ];
    });
    dataDir = "/var/db/postgresql";
    # https://pgtune.leopard.in.ua/#/
    logLinePrefix = "user=%u,db=%d,app=%a,client=%h ";
    settings = {
      listen_addresses = lib.mkForce "10.254.1.9";

      checkpoint_completion_target = "0.9";
      default_statistics_target = 100;

      log_duration = "off";
      log_statement = "none";

      # pgbadger-compatible logging
      log_transaction_sample_rate = 0.01;
      log_min_duration_statement = 5000;
      log_checkpoints = "on";
      log_connections = "on";
      log_disconnections = "on";
      log_lock_waits = "on";
      log_temp_files = 0;
      log_autovacuum_min_duration = 0;

      max_connections = 500;
      work_mem = "20MB";
      maintenance_work_mem = "2GB";

      # 25% of memory
      shared_buffers = "16GB";

      # Checkpoint every 1GB. (default)
      # increased after seeing many warninsg about frequent checkpoints
      min_wal_size = "1GB";
      max_wal_size = "2GB";
      wal_buffers = "16MB";

      max_worker_processes = 16;
      max_parallel_workers_per_gather = 8;
      max_parallel_workers = 16;

      # NVMe related performance tuning
      effective_io_concurrency = 200;
      random_page_cost = "1.1";

      # We can risk losing some transactions.
      synchronous_commit = "off";

      effective_cache_size = "16GB";

      # Enable JIT compilation if possible.
      jit = "on";

      # autovacuum and autoanalyze much more frequently:
      # at these values vacuum should run approximately
      # every 2 mass rebuilds, or a couple times a day
      # on the builds table. Some of those queries really
      # benefit from frequent vacuums, so this should
      # help. In particular, I'm thinking the jobsets
      # pages.
      autovacuum_vacuum_scale_factor = 0.002;
      autovacuum_analyze_scale_factor = 0.001;

      shared_preload_libraries = "pg_stat_statements";
      compute_query_id = "on";
    };

    # FIXME: don't use 'trust'.
    authentication = ''
      host hydra all 10.254.1.3/32 trust
      host hydra all 10.254.1.5/32 trust
      local all root peer map=prometheus
    '';

    identMap = ''
      prometheus root root
      prometheus postgres-exporter root
    '';
  };

  networking = {
    firewall.interfaces.wg0.allowedTCPPorts = [ 5432 ];
    firewall.allowPing = true;
    firewall.logRefusedConnections = true;
  };

  services.prometheus.exporters.postgres = {
    enable = true;
    dataSourceName = "user=root database=hydra host=/run/postgresql sslmode=disable";
    firewallFilter = "-i wg0 -p tcp -m tcp --dport 9187";
    openFirewall = true;
    extraFlags = [ "--extend.query-path" "${pkgs.prometheus-postgres-exporter.src}/queries.yaml" ];
  };

  programs.ssh = {
    knownHosts = {
      rsync-net = {
        hostNames = [ "zh2543b.rsync.net" "2001:1620:2019::324" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKlIcNwmx7id/XdYKZzVX2KtZQ4PAsEa9KVQ9N43L3PX";
      };
      ma27-backup-server = {
        hostNames = [ "mbosch.me" "135.181.78.102" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG6rlyYpWzzt1Fn4c9XdrgzuVqlnhzXz6BRReDVz9I/n";
      };
      delroth-backup-server = {
        hostNames = [ "smol.delroth.net" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9Ta4DYE3YxXzV57s6TX6KEbIa3O4re+J4NzATCOiXb";
      };
    };
  };

  services.zfs.autoScrub.enable = true;

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
              "3x5m"
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
              "20x5m"
              "96x1h"
              "12x4h"
              "7x1d"
              "52x1w"
              "120x3w"
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
          name = "delroth";
          connect = {
            identity_file = "/root/.ssh/id_ed25519";
            type = "ssh+stdinserver";
            host = "smol.delroth.net";
            user = "zrepl";
            port = 22;
          };
        })

        # XXX: Seems to be broken as of 2024-02-12 (permission denied).
        {
          # run with `zrepl signal wakeup safe_ma27` after
          # snapshots were done from safe.
          name = "safe_ma27";
          type = "push";
          filesystems."rpool/safe/postgres" = true;
          snapshotting.type = "manual";
          connect = {
            identity_file = "/root/.ssh/id_ed25519";
            type = "ssh+stdinserver";
            host = "135.181.78.102"; # "mbosch.me" has broken IPv6, tsk tsk.
            user = "hno";
            port = 22;
          };
          pruning = {
            keep_sender = [
              {
                type = "regex";
                regex = ".*";
              }
            ];
            keep_receiver = [
              {
                type = "regex";
                regex = ".*";
              }
            ];
          };
        }
      ];
    };
  };
}
