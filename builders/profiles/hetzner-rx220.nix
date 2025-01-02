{
  imports = [
    ../boot/efi-grub.nix
  ];

  disko.devices = import ../disk-layouts/efi-zfs-raid0.nix { };
  boot.supportedFilesystems.zfs = true;
  networking.hostId = "91312b0a";

  # 96G for build roots, 160G for working memory
  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "96G";
  };

  boot.initrd.availableKernelModules = [
    "nvme"
    "usbhid"
  ];
}
