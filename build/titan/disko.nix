let
  layout = id: {
    type = "gpt";
    partitions = {
      esp = {
        type = "EF00";
        size = "1G";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/efi/${id}";
        };
      };
      zfs = {
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
    nvme0n1 = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-MTFDKCC1T9TGP-1BK1DABYY_0925109FB623";
      content = layout "a";
    };
    nvme1n1 = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-MTFDKCC1T9TGP-1BK1DABYY_0925109FB922";
      content = layout "b";
    };
  };

  zpool.zroot = {
    type = "zpool";
    mode = "mirror";
    options.ashift = "12";

    rootFsOptions = {
      acltype = "posixacl";
      atime = "off";
      compression = "zstd-3";
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
      "pg" = {
        type = "zfs_fs";
        mountpoint = "/var/lib/postgresql";
        options = {
          logbias = "latency";
          recordsize = "16K";
          redundant_metadata = "most";
        };
      };
      "reserved" = {
        type = "zfs_fs";
        options = {
          canmount = "off";
          refreservation = "16G"; # roughly one system closure
        };
      };
    };
  };
}
