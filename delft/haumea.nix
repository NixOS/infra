{ config, lib, pkgs, ...}:

{
  imports =
    [ ./common.nix
      ./datadog.nix
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

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_11;
    # https://pgtune.leopard.in.ua/#/
    extraConfig = ''
      listen_addresses = '10.254.1.9'
      max_connections = 50

      effective_cache_size = 48GB
      checkpoint_completion_target = 0.9
      default_statistics_target = 100

      log_min_duration_statement = 5000
      log_duration = off
      log_statement = 'none'
      max_connections = 250
      work_mem = 20MB
      maintenance_work_mem = 2GB

      # 25% of memory
      shared_buffers = 16GB

      # Checkpoint every 1GB. (default)
      # increased after seeing many warninsg about frequent checkpoints
      min_wal_size = 1GB
      max_wal_size = 2GB
      wal_buffers = 16MB

      max_worker_processes = 16
      max_parallel_workers_per_gather = 8
      max_parallel_workers = 16

      # NVMe related performance tuning
      effective_io_concurrency = 200
      random_page_cost = 1.1

      # We can risk losing some transactions.
      synchronous_commit = off

      effective_cache_size = 16GB
    '';

    # FIXME: don't use 'trust'.
    authentication = ''
      host hydra all 10.254.1.3/32 trust
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
  };
}
