{ config, pkgs, ... }:

{
  require = [ ./common.nix ];
  
  environment.nix = pkgs.nixSqlite;

  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.copyKernels = true;
  boot.kernelPackages = pkgs.linuxPackages_2_6_32;

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
}
