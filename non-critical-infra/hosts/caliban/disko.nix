let
  partitions = {
    grub = {
      priority = 1;
      start = "0";
      end = "1M";
      type = "EF02";
    };
    boot = {
      priority = 2;
      name = "boot";
      start = "1M";
      end = "1G";
      content = {
        type = "filesystem";
        format = "vfat";
      };
    };
    root = {
      priority = 3;
      start = "1G";
      end = "100%";
      content = {
        type = "zfs";
        pool = "zroot";
      };
    };
  };
in
{
  disk = {
    nvme0n1 = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        inherit partitions;
      };
    };
    nvme1n1 = {
      type = "disk";
      device = "/dev/nvme1n1";
      content = {
        type = "gpt";
        inherit partitions;
      };
    };
  };

  zpool = {
    zroot = {
      type = "zpool";
      mode = "mirror";
      rootFsOptions = {
        compression = "lz4";
        "com.sun:auto-snapshot" = "true";
        mountpoint = "none";
      };
      datasets = {
        "root" = {
          type = "zfs_fs";
          options.mountpoint = "none";
          mountpoint = null;
        };
        "root/nixos" = {
          type = "zfs_fs";
          options.mountpoint = "/";
          mountpoint = "/";
        };
      };
    };
  };
}
