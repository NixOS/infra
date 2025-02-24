{ lib, ... }:

{

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "virtio_pci"
    "usbhid"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ "virtio_gpu" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
