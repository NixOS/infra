{
  boot.loader.grub = {
    devices = [
      "/dev/nvme0n1"
      "/dev/nvme1n1"
    ];
    copyKernels = true;
  };
  boot.initrd.availableKernelModules = [ "ahci" "nvme" "usbhid" ];
  boot.kernelModules = [ "kvm-amd" ];
}
