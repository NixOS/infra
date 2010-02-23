{ config, pkgs, ... }:

{
  require = [ ./common.nix ];

  boot.grubDevice = "/dev/sda";
  boot.kernelPackages = pkgs.linuxPackages_2_6_32;
  boot.copyKernels = true;

  fileSystems =
    [ { mountPoint = "/";
        label = "nixos";
      }
    ];

  swapDevices = [ { label = "swap"; } ];

  nix.extraOptions =
    ''
      build-max-silent-time = 3600
    '';

  services.cron.systemCronJobs =
    [ "15 03 * * * root ${pkgs.nixUnstable}/bin/nix-collect-garbage --max-freed $((32 * 1024**3)) > /var/log/gc.log 2>&1"
    ];

  networking.hostName = ""; # obtain from DHCP server
}
