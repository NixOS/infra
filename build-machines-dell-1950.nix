# Configuration for the Dell PowerEdge 1950 build machines.

{ config, pkgs, ... }:

{
  require = [ ./build-machines-common.nix ];

  nixpkgs.system = "x86_64-linux";

  boot.initrd.kernelModules = [ "mptsas" "ext4" ];
  boot.kernelModules = [ "acpi-cpufreq" "kvm-intel" ];

  nix.maxJobs = 8;
}
