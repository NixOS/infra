{ config, lib, pkgs, ...}:

{
  imports =
    [ ./common.nix
      # ./datadog.nix # error: psycopg2-2.9.1 not supported for interpreter python2.7
      ./fstrim.nix
    ];

  environment.systemPackages = [ pkgs.lz4 ];

  deployment.targetEnv = "hetzner";
  deployment.hetzner.mainIPv4 = "46.4.89.205";

  deployment.hetzner.partitionCommand =
    ''
      if ! [ -e /usr/local/sbin/zfs ]; then
        echo "installing zfs..."
        bash -i -c 'echo y | zfsonlinux_install'
      fi

      umount -R /mnt || true

      zpool destroy rpool || true

      for disk in /dev/nvme0n1 /dev/nvme1n1; do
        echo "partitioning $disk..."
        index="''${disk: -3:1}"
        parted -s $disk "mklabel msdos"
        parted -a optimal -s $disk "mkpart primary ext4 1m 256m"
        parted -a optimal -s $disk "mkpart primary zfs 256m 100%"
        udevadm settle
        mkfs.ext4 -L boot$index ''${disk}p1
      done

      echo "creating ZFS pool..."
      zpool create -f -o ashift=12 \
        -O mountpoint=legacy -O atime=off -O compression=lz4 -O xattr=sa -O acltype=posixacl \
        rpool mirror /dev/nvme0n1p2 /dev/nvme1n1p2

      zfs create rpool/local
      zfs create rpool/local/nix
      zfs create rpool/safe
      zfs create rpool/safe/root
      zfs create -o primarycache=all -o recordsize=16k -o logbias=throughput rpool/safe/postgres
    '';

  deployment.hetzner.mountCommand =
    ''
      mkdir -p /mnt
      mount -t zfs rpool/safe/root /mnt
      mkdir -p /mnt/nix
      mount -t zfs rpool/local/nix /mnt/nix
      mkdir -p /mnt/var/db/postgresql
      mount -t zfs rpool/safe/postgres /mnt/var/db/postgresql
      mkdir -p /mnt/boot
      mount /dev/disk/by-label/boot0 /mnt/boot
    '';

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
    extraConfig = ''
      Host rob-backup-server
      Hostname 83.162.34.61
      User nixosfoundationbackups
      Port 6666
    '';

    knownHosts = {
      graham-backup-server = {
        hostNames = [ "lord-nibbler.gsc.io" "67.246.1.194" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEjBFLoalf56exb7GptkI151ee+05CwvXzoyBuvzzUbK";
      };
      rob-backup-server = {
        hostNames = [ "[83.162.34.61]:6666" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKKUSblYu3vgZOY4hsezAx8pwwsgVyDsnZLT9M0zZsgZ";
      };
      ma27-backup-server = {
        hostNames = [ "mbosch.me" "135.181.78.102" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG6rlyYpWzzt1Fn4c9XdrgzuVqlnhzXz6BRReDVz9I/n";
      };
    };
  };

  services.zfs.autoScrub.enable = true;

  services.zrepl = {
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
        #{ name = "local";
        #  type = "snap";
        #  filesystems."rpool/local<" = true;
        #  snapshotting = {
        #    type = "periodic";
        #    interval = "5m";
        #    prefix = "zrepl_snap_";
        #  };
        #  pruning.keep = [
        #    {
        #      type = "grid";
        #      regex = "^zrepl_snap_.*";
        #      grid = lib.concatStringsSep " | " [
        #        "3x5m"
        #        "4x15m"
        #        "24x1h"
        #        "4x1d"
        #        "3x1w"
        #      ];
        #    }
        #  ];
        #}
        {
          name = "safe";
          type = "push";
          filesystems."rpool/safe<" = true;
          send.encrypted = true;
          snapshotting = {
            type = "periodic";
            interval = "5m";
            prefix = "zrepl_snap_";
          };
          connect = {
            identity_file = "/root/.ssh/id_ed25519";
            type = "ssh+stdinserver";
            host = "lord-nibbler.gsc.io";
            user = "hydraexport";
            port = 22;
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
        }
        {
          # run with `zrepl signal wakeup safe_ma27` after
          # snapshots were done from safe.
          name = "safe_ma27";
          type = "push";
          filesystems."rpool/safe/postgres" = true;
          send.encrypted = true;
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

  services.znapzend = {
    enable = true;
    autoCreation = true;
    pure = true;
    zetup = {
      "rpool/local" = {
        enable = true;
        recursive = true;
        plan = "15min=>5min,1hour=>15min,1day=>1hour,4day=>1day,3week=>1week";
        timestampFormat = "%Y-%m-%dT%H:%M:%SZ";
      };

      "rpool/safe" = {
        enable = true;
        plan = "15min=>5min,1hour=>15min,1day=>1hour,4day=>1day,3week=>1week";
        recursive = true;
        timestampFormat = "%Y-%m-%dT%H:%M:%SZ";
        destinations = {
          ogden = {
            plan = "1hour=>5min,4day=>1hour,1week=>1day,1year=>1week,10year=>1month";
            host = "hydraexport@lord-nibbler.gsc.io";
            dataset = "rpool/backups/nixos.org/haumea/safe";
          };
/*
          rob = {
            plan = "1hour=>5min,4day=>1hour,1week=>1day,1year=>1week,10year=>1month";
            host = "rob-backup-server";
            dataset = "tank/nixos-org/haumea/safe";
          };
*/
        };
      };
    };
  };
}
