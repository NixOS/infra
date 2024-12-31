{
  disk1 ? "/dev/nvme0n1",
  disk2 ? "/dev/nvme1n1",
}:
let
  mkDiskLayout = id: {
    type = "gpt";
    partitions = {
      esp = {
        type = "EF00";
        size = "512M";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/efi/${id}";
        };
      };
      zdev = {
        size = "100%";
        content = {
          type = "zfs";
          pool = "zroot";
        };
      };
    };
  };
in
{
  disk = {
    a = {
      type = "disk";
      device = disk1;
      content = mkDiskLayout "a";
    };

    b = {
      type = "disk";
      device = disk2;
      content = mkDiskLayout "b";
    };
  };

  zpool.zroot = {
    mode = ""; # RAID 0
    options.ashift = "12"; # 4k blocks

    rootFsOptions = {
      acltype = "posixacl";
      atime = "off";
      compression = "on";
      mountpoint = "none";
      xattr = "sa";
    };

    datasets = {
      root = {
        type = "zfs_fs";
        mountpoint = "/";
      };
      reserved = {
        type = "zfs_fs";
        options = {
          canmount = "off";
          refreservation = "16G"; # roughly one system closure
        };
      };
    };
  };
}
