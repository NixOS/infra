{ nodes, config, lib, pkgs, ... }:

{
  imports =
    [ ./common.nix
#      ./hydra.nix
#      ./hydra-proxy.nix
#      ./fstrim.nix
#      ./packet-importer.nix
    ];

  deployment.targetEnv = "hetzner";
  deployment.hetzner.mainIPv4 = "5.9.122.43";

  deployment.hetzner.partitions = ''
      set -eux

      if ! [ -e /usr/local/sbin/zfs ]; then
        echo "installing zfs..."
        bash -i -c 'echo y | zfsonlinux_install'
      fi

      umount -R /mnt || true

      zpool destroy rpool || true


      for disk in /dev/nvme0n1 /dev/nvme1n1; do
        echo "partitioning $disk..."
        index="''${disk: -3:1}"
        parted -s $disk "mklabel gpt"
        parted -a optimal -s $disk "mkpart primary fat32 1m 512m"
        parted -a optimal -s $disk "mkpart primary zfs 512m 100%"
        parted -s $disk "set 1 esp on"
        udevadm settle
        mkfs.vfat -n BOOT$index ''${disk}p1
      done

      zpool create -f -o ashift=12 -o autotrim=on \
        -O mountpoint=legacy -O atime=off -O compression=on \
        rpool mirror /dev/nvme0n1p2 /dev/nvme1n1p2

      zfs create rpool/local
      zfs create rpool/local/nix
      zfs create -o recordsize=4k rpool/local/nix/db
      zfs create -o xattr=sa -o acltype=posix rpool/local/var
      zfs create rpool/safe
      zfs create rpool/safe/root

      mkdir -p /mnt
      mount -t zfs rpool/safe/root /mnt

      mkdir -p /mnt/nix
      mount -t zfs rpool/local/nix /mnt/nix

      mkdir -p /mnt/nix/var/nix/db
      mount -t zfs rpool/local/nix/db /mnt/nix/var/nix/db

      mkdir -p /mnt/var
      mount -t zfs rpool/local/var /mnt/var

      mkdir -p /mnt/boot
      mount /dev/disk/by-label/BOOT0 /mnt/boot
  '';

  networking = {
    firewall.allowedTCPPorts = [
      80 443
      9199 # hydra-notify's prometheus
    ];
    firewall.allowPing = true;
    firewall.logRefusedConnections = false;
  };

  time.timeZone = lib.mkForce "UTC";
  system.stateVersion = lib.mkForce "21.11";
}

