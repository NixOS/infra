# Matches the existing disk layout on nixos.lysator.liu.se:
# 3x 1.8T disks in raidz1 ZFS pool "tank", each with a 1G EFI partition
let
  espPartition = mountpoint: {
    type = "EF00";
    size = "1G";
    content = {
      type = "filesystem";
      format = "vfat";
      inherit mountpoint;
      mountOptions = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };

  zfsPart = {
    size = "100%";
    content = {
      type = "zfs";
      pool = "tank";
    };
  };

  makeDisk = device: espMountpoint: {
    inherit device;
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        esp = espPartition espMountpoint;
        zfs = zfsPart;
      };
    };
  };
in
{
  disk = {
    sda = makeDisk "/dev/disk/by-id/wwn-0x5000cca222c595d2" "/boot";
    sdb = makeDisk "/dev/disk/by-id/wwn-0x5000cca222c1c46e" "/boot-fallback/1";
    sdc = makeDisk "/dev/disk/by-id/wwn-0x5000cca222c5c6d3" "/boot-fallback/2";
  };

  zpool.tank = {
    type = "zpool";
    mode = "raidz1";
    options = {
      ashift = "12";
    };
    rootFsOptions = {
      compression = "on";
      mountpoint = "none";
      acltype = "posix";
      xattr = "on";
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
      "var" = {
        type = "zfs_fs";
        mountpoint = "/var";
      };
      "home" = {
        type = "zfs_fs";
        mountpoint = "/home";
      };
    };
  };
}
