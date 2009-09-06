{ config, pkgs, ... }:

{
  boot.grubDevice = "/dev/sda";
  boot.kernelPackages = pkgs.kernelPackages_2_6_29;
  boot.copyKernels = true;

  boot.postBootCommands =
    ''
      echo 60 > /proc/sys/kernel/panic
    '';
      
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

  services.sshd.enable = true;

  services.cron.systemCronJobs =
    [ "15 03 * * * root ${pkgs.nixUnstable}/bin/nix-collect-garbage --max-freed $((32 * 1024**3)) > /var/log/gc.log 2>&1"
    ];

  networking.hostName = ""; # obtain from DHCP server

  environment.systemPackages = [pkgs.emacs];
}