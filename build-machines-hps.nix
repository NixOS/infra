# Configuration for the HPS build machines.

{ config, pkgs, ... }:

{
  require = [ ./build-machines-common.nix ];
  
  nixpkgs.system = "x86_64-linux";

  boot.initrd.kernelModules = ["3w_xxxx"];
  boot.kernelModules = ["kvm-intel"];

  nix.maxJobs = 2;
}
