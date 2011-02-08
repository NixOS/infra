# NixOS test machine.

{ config, pkgs, modulesPath, ... }:

{
  require = [ "${modulesPath}/virtualisation/xen-domU.nix" ];

  networking.hostName = "";

  fileSystems = 
    [ { mountPoint = "/";
        label = "nixos";
      }
      { mountPoint = "/boot";
        label = "boot";
      }
    ];

  services.openssh.enable = true;
}
