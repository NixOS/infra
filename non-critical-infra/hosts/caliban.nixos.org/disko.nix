let
  partitions = [
    {
      name = "grub";
      start = "0";
      end = "1M";
      part-type = "primary";
      flags = [ "bios_grub" ];
    }
    {
      name = "boot";
      start = "1M";
      end = "1G";
      part-type = "primary";
      content = {
        type = "filesystem";
        format = "vfat";
      };
    }
    {
      name = "root";
      start = "1G";
      end = "100%";
      part-type = "primary";
      bootable = true;
      content = {
        type = "zfs";
        pool = "zroot";
      };
    }
  ];
in
{
  disk = {
    nvme0n1 = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "table";
        format = "gpt";
        inherit partitions;
      };
    };
    nvme1n1 = {
      type = "disk";
      device = "/dev/nvme1n1";
      content = {
        type = "table";
        format = "gpt";
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


