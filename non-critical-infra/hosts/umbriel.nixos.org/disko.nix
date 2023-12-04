{
  disk = {
    main = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            type = "EF00";
            size = "1024M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/efi";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "zroot";
            };
          };
        };
      };
    };
  };

  zpool.zroot = {
    type = "zpool";
    options = {
      # smartctl --all /dev/sda
      # Logical block size:   512 bytes
      ashift = "9";
    };
    rootFsOptions = {
      acltype = "posixacl";
      compression = "zstd";
      mountpoint = "none";
      xattr = "sa";
    };
    datasets = {
      "root" = {
        type = "zfs_fs";
        mountpoint = "/";
      };
      "nix" = {
        type = "zfs_fs";
        mountpoint = "/nix";
      };
      "reserved" = {
        type = "zfs_fs";
        options = {
          canmount = "off";
          refreservation = "1G";
        };
      };
    };
  };
}

