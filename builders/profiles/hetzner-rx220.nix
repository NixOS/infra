{
  imports = [
    ../boot/efi-grub.nix
  ];

  disko.devices = import ../disk-layouts/efi-zfs-raid0.nix { };
  boot.supportedFilesystems.zfs = true;
  networking.hostId = "91312b0a";

  boot.initrd.availableKernelModules = [
    "nvme"
    "usbhid"
  ];
}
