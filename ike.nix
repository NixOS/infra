{ config, pkgs, ... }:

{
  boot.loader.grub.version = 2;
  require = [ ./build-machines-common.nix ];
  nixpkgs.system = "x86_64-linux";

  boot.initrd.kernelModules = [ "megaraid_sas" "ext4" ];
  boot.kernelModules = [ "acpi-cpufreq" "kvm-amd" ];

  nix.maxJobs = 8;
}
