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

  services.cron.systemCronJobs =
    [ # Make sure that at least 100 GiB of disk space is available.
      "15 03 * * * root  nix-store --gc --max-freed \"$((100 * 1024**3 - 1024 * $(df /nix/store | tail -n 1 | awk '{ print $4 }')))\" > /var/log/gc.log 2>&1"
    ];

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
    
}
