# Configuration for the Dell PowerEdge 1950 build machines.

{ config, pkgs, ... }:

{
  imports = [ ./build-machines-common.nix ];

  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.copyKernels = true;

  fileSystems =
    [ { mountPoint = "/";
        label = "nixos";
        options = "noatime";
      }
    ];

  boot.initrd.kernelModules = [ "mptsas" "ext4" ];
  boot.kernelModules = [ "acpi-cpufreq" "kvm-intel" ];

  nix.maxJobs = 8;

  swapDevices = [ { label = "swap"; } ];
}
