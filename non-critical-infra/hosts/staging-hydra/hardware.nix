{ lib, ... }:
{

  boot.initrd = {
    availableKernelModules = [
      "xhci_pci"
      "virtio_pci"
      "usbhid"
      "sr_mod"
    ];
    kernelModules = [ "virtio_gpu" ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
