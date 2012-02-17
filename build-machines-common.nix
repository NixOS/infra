{ config, pkgs, ... }:

with pkgs.lib;

{
  require = [ ./common.nix ];
  
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.copyKernels = true;

  fileSystems =
    [ { mountPoint = "/";
        label = "nixos";
        options = "noatime";
      }
    ];

  swapDevices = [ { label = "swap"; } ];

  nix.extraOptions =
    ''
      build-max-silent-time = 3600
    '';

  nix.gc.automatic = true;
  nix.gc.dates = "15 03,09,15,21 * * *";
  nix.gc.options = ''--max-freed "$((100 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | awk '{ print $4 }')))"'';

  networking.hostName = ""; # obtain from DHCP server

  users.extraUsers =
    [ { name = "buildfarm";
        description = "Hydra unprivileged build slave";
        group = "users";
        home = "/home/buildfarm";
        useDefaultShell = true;
        createHome = true;
        isSystemUser = false;
      }
    ];

  # !!! Should have a NixOS option for installing files into a declarative user account.
  system.activationScripts.buildfarmSSHKey = stringAfter [ "users" ]
    ''
      mkdir -m 700 -p /home/buildfarm/.ssh
      cp ${./id_buildfarm.pub} /home/buildfarm/.ssh/authorized_keys
      chown -R buildfarm.users /home/buildfarm/.ssh
    '';
    
  jobs.udevtrigger.postStop =
    ''
      # Enable Kernel Samepage Merging (reduces memory footprint of
      # VMs).
      echo 1 > /sys/kernel/mm/ksm/run
    '';

}
