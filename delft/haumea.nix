{ config, lib, pkgs, ...}:

{
  imports =
    [ ./common.nix
      ./datadog.nix
      ./fstrim.nix
    ];

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
      mkdir -p /mnt/var/lib/postgresql
      mount -t zfs rpool/safe/postgres /mnt/var/lib/postgresql
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

  fileSystems."/var/lib/postgresql" =
    { device = "rpool/safe/postgres";
      fsType = "zfs";
    };

  networking.hostId = "83c81a23";

  boot.loader.grub.devices = [ "/dev/nvme0n1" "/dev/nvme1n1" ];
  boot.loader.grub.copyKernels = true;
}
