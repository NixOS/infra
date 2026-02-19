{
  disko.devices = {
    disk = {
      nvme0n1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL2512HDJD-00B07_S782NE0W900172";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/efi/a";
              };
            };
            swap = {
              size = "16G";
              content = {
                type = "swap";
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
      };
      nvme1n1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL2512HDJD-00B07_S782NF0YA37531";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/efi/b";
              };
            };
            swap = {
              size = "16G";
              content = {
                type = "swap";
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
      };
    };
    zpool = {
      zroot = {
        type = "zpool";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        mode = "mirror";
        rootFsOptions = {
          acltype = "posixacl";
          compression = "zstd";
          mountpoint = "none";
        };

        datasets = {
          root = {
            type = "zfs_fs";
            mountpoint = "/";
          };
          "root/prometheus" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/prometheus2";
          };
          "root/victoriametrics" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/victoriametrics";
          };
        };
      };
    };
  };
}
