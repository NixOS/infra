# Configuration for the HPS build machines.

{ config, pkgs, ... }:

{
  require = [ ./build-machines-common.nix ];
  
  boot.initrd.extraKernelModules = ["3w_xxxx"];
  boot.kernelModules = ["kvm-intel"];

  nix.maxJobs = 2;
  
  services.zabbixAgent = {
    enable = true;
    server = "192.168.1.5";
  };
}
