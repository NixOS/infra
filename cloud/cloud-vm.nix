{ config, pkgs, ... }:

{
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/vda";
  boot.initrd.kernelModules = [ "virtio_blk" "virtio_pci" ];

  fileSystems =
    [ { mountPoint = "/";
        label = "nixos";
      }
    ];

  swapDevices = [ { label = "swap"; } ];

  networking.hostName = "";
  networking.firewall.enable = true;

  services.openssh.enable = true;

  services.mingetty.ttys = [ "hvc0" "tty1" "tty2" ];
}
