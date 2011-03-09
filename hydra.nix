{ config, pkgs, ... }:

{
  require = [ ./common.nix ];

  nixpkgs.system = "x86_64-linux";

  boot = {
    initrd.kernelModules = [ "mptsas" "ext4" ];
    kernelModules = [ "acpi-cpufreq" "kvm-intel" ];
    loader.grub.device = "/dev/sda";
    loader.grub.copyKernels = true;
  };

  fileSystems =
    [ { mountPoint = "/";
        label = "nixos";
        options = "noatime,barrier=0,data=ordered";
      }
    ];
 
  #swapDevices = [ { label = "swap" ; } ];

  nix.maxJobs = 8;

  networking = {
    hostName = "hydra";
    domain = "buildfarm";
  };

  services.cron.systemCronJobs =
    [
      # Make sure that at least 200 GiB of disk space is available.
      "15 3 * * * root  nix-store --gc --max-freed \"$((200 * 1024**3 - 1024 * $(df /nix/store | tail -n 1 | awk '{ print $4 }')))\" > /var/log/gc.log 2>&1"
    ];

}
