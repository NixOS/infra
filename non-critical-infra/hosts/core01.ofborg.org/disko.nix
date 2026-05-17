{
  disk = {
    main = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          grub = {
            size = "1M";
            type = "EF02";
          };
          boot = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
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

  zpool = {
    zroot = {
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
  };
}
