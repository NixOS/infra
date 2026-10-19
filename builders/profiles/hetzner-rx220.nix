{
  pkgs,
  ...
}:

{
  imports = [
    ../boot/efi-grub.nix
  ];

  disko.devices = import ../disk-layouts/efi-zfs-raid0.nix { };
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems.zfs = true;
  boot.zfs.forceImportRoot = false;
  networking.hostId = "91312b0a";

  boot.initrd.availableKernelModules = [
    "nvme"
    "usbhid"
  ];
}
