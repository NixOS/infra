{
  boot = {
    initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "nvme"
      "usbhid"
    ];
    kernelParams = [
      "zfs_arc_max=68719476736.0" # 64 GiB
    ];
    supportedFilesystems.zfs = true;
    loader = {
      efi.canTouchEfiVariables = false;
      grub = {
        enable = true;
        configurationLimit = 10;
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
