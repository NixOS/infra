{ config, pkgs, ... }:

with pkgs.lib;

{
  require = [ ./common.nix ];

  virtualisation.xen.enable = true;
  virtualisation.xen.domain0MemorySize = 512;

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

  environment.etc =
    flip map (range 0 9) (nr:
      { source = pkgs.writeText "agilecloud0${toString nr}"
          ''
            from xen.util.path import *
            memory = 512
            kernel = XENFIRMWAREDIR + '/pv-grub-x86_32.gz'
            extra = '(hd0)/boot/grub/menu.lst'
            disk = [ 'file:/vmdisks/agilecloud-0${toString nr}-root.img,xvda1,w' ]
            vif = [ 'mac=00:16:3e:00:34:0${toString nr}' ]
          '';
        target = "xen/agilecloud0${toString nr}";
      }
    );
}
