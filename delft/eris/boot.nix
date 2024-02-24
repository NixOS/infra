{
  boot.loader.grub = {
    devices = [
      "/dev/sda"
      "/dev/sdb"
    ];
  };
  boot.initrd.availableKernelModules = [ "ahci" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
}
