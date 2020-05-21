{
  edition = 201909;

  inputs.nixpkgs.url = "nixpkgs/nixos-20.03";

  outputs = { self, nixpkgs, nix, hydra }: {

    nixopsConfigurations.default = {
      inherit nixpkgs;

      makemake =
        { config, lib, pkgs, ... }:

        { imports =
            [ ../../modules/common.nix
              hydra.nixosModules.hydra
              ./hydra.nix
              ./hydra-proxy.nix
            ];

          nixpkgs.overlays =
            [ nix.overlay
            ];

          system.configurationRevision = self.rev
            or (throw "Cannot deploy from an unclean source tree!");

          deployment.targetEnv = "hetzner";
          deployment.hetzner.mainIPv4 = "116.202.113.248"; # 2a01:4f8:231:4187::2
          deployment.hetzner.createSubAccount = false;

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
              zpool create -f -o ashift=12 -O atime=off -O compression=lz4 -O xattr=sa -O acltype=posixacl \
                rpool mirror /dev/nvme0n1p2 /dev/nvme1n1p2
              zfs set mountpoint=legacy rpool

              zfs create -o primarycache=all -o recordsize=16k -o logbias=throughput rpool/root
              zfs create -o primarycache=all -o recordsize=16k -o logbias=throughput rpool/postgres
            '';

          deployment.hetzner.mountCommand =
            ''
              mkdir -p /mnt
              mount -t zfs rpool/root /mnt
              mkdir -p /mnt/postgres
              mount -t zfs rpool/postgres /mnt/postgres
              mkdir -p /mnt/boot
              mount /dev/disk/by-label/boot0 /mnt/boot
            '';

          fileSystems."/" =
            { device = "rpool/root";
              fsType = "zfs";
            };

          fileSystems."/boot" =
            { device = "/dev/disk/by-label/boot0";
              fsType = "ext4";
            };

          fileSystems."/postgres" =
            { device = "rpool/postgres";
              fsType = "zfs";
            };

          networking = {
            hostId = "5240310e";
            firewall.allowedTCPPorts = [ 80 443 ];
            firewall.allowPing = true;
            firewall.logRefusedConnections = true;
          };

          boot.loader.grub.devices = [ "/dev/nvme0n1" "/dev/nvme1n1" ];
          boot.loader.grub.copyKernels = true;

          users.extraUsers.root.openssh.authorizedKeys.keys =
            with import ../../ssh-keys.nix; [ zimbatm ];
        };
    };

  };
}
