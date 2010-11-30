{ config, pkgs, ... }:

{
  require = [ ./common.nix ];

  virtualisation.xen.enable = true;
  virtualisation.xen.domain0MemorySize = 512;

  boot.grubDevice = "/dev/sda";
  boot.initrd.extraKernelModules = [ "mptbase" "mptscsih" "mptsas" ];

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
