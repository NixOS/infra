# Configuration for the Dell PowerEdge 1950 build machines.

{ config, pkgs, ... }:

{
  require = [ ./build-machines-common.nix ];

  boot.initrd.extraKernelModules = ["uhci_hcd" "ehci_hcd" "ata_piix" "mptsas" "usbhid" "ext4"];
  boot.kernelModules = ["acpi-cpufreq" "kvm-intel"];

  nix.maxJobs = 8;

  environment.extraPackages = [pkgs.emacs];
}
