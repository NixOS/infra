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

  # The kernel's default overcommit heuristic renders Nix incapable of
  # forking on machines with little RAM (unless GC_INITIAL_HEAP_SIZE
  # is set to a low value).  So turn off checking.
  boot.postBootCommands =
    ''
      echo 1 > /proc/sys/vm/overcommit_memory
    '';
}
