{
  boot.loader.grub = {
    devices = [
      "/dev/nvme0n1"
      "/dev/nvme1n1"
    ];
    copyKernels = true;
    configurationLimit = 10; # 230 MB /boot capacity
  };
  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "usbhid"
  ];
  boot.kernelModules = [ "kvm-amd" ];
}
