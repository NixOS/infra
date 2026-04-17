{

  boot.initrd.availableKernelModules = [
    "ehci_pci"
    "ahci"
  ];
  boot.initrd.kernelModules = [ "nvme" ];
  boot.kernelModules = [ "kvm-intel" ];
}
