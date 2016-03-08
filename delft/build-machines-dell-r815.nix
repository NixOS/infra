{ config, pkgs, ... }:

{
  imports = [ ./build-machines-common.nix ./megacli.nix ];

  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.copyKernels = true;

  fileSystems."/" =
    { label = "nixos";
      options = "noatime";
    };

  fileSystems."/tmp" =
    { device = "none";
      fsType = "tmpfs";
      options = "size=50%";
      neededForBoot = true;
    };

  boot.initrd.kernelModules = [ "megaraid_sas" "ext4" ];
  boot.kernelModules = [ "acpi-cpufreq" "kvm-amd" ];

  nix.maxJobs = 48;
}
