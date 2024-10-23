let
  layout = id: {
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
      device = "/dev/disk/by-id/nvme-SAMSUNG_MZQL21T9HCJR-00A07_S64GNNFX604905";
      content = layout "a";
    };
    nvme1n1 = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-SAMSUNG_MZQL21T9HCJR-00A07_S64GNNFX604919";
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
      compression = "on";
      mountpoint = "none";
      xattr = "sa";
    };

    datasets = {
      "root" = {
        type = "zfs_fs";
        mountpoint = "/";
      };
      "nix/store" = {
        type = "zfs_fs";
        mountpoint = "/nix";
      };
      "nix/db" = {
        type = "zfs_fs";
        mountpoint = "/nix/var/nix/db";
      };
      "hydra/cache" = {
        type = "zfs_fs";
        mountpoint = "/var/cache/hydra";
      };
      "hydra/state" = {
        type = "zfs_fs";
        mountpoint = "/var/lib/hydra";
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
