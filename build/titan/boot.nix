{
  boot = {
    initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "nvme"
      "usbhid"
    ];
    kernelModules = [ "kvm-amd" ];
    supportedFilesystems.zfs = true;
    loader = {
      efi.canTouchEfiVariables = false;
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        mirroredBoots = [
          {
            devices = [ "nodev" ];
            path = "/efi/a";
          }
          {
            devices = [ "nodev" ];
            path = "/efi/b";
          }
        ];
      };
    };
  };
}
