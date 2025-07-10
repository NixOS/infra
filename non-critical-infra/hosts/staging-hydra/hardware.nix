{ lib, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  boot.initrd = {
    availableKernelModules = [
      "xhci_pci"
      "virtio_pci"
      "virtio_scsi"
      "usbhid"
      "sr_mod"
    ];
    kernelModules = [ "virtio_gpu" ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
