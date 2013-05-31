{ config, pkgs, ... }:

with pkgs.lib;

{
  require = [ ./common.nix ];

  nixpkgs.system = "x86_64-linux";

  #virtualisation.xen.enable = true;
  #virtualisation.xen.domain0MemorySize = 512;

  boot.loader.grub.device = "/dev/sda";
  boot.initrd.kernelModules = [ "mptbase" "mptscsih" "mptsas" ];

  fileSystems = 
    [ { mountPoint = "/";
        label = "nixos";
        fsType = "ext3";
      }
    ];

  swapDevices = [ { label = "swap"; } ];

  networking.hostName = "";

  services.openssh.enable = true;
}
