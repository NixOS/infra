{
  imports = [
    ../boot/efi-grub.nix
  ];

  disko.devices = import ../disk-layouts/efi-zfs-raid0.nix { };
  boot.supportedFilesystems.zfs = true;
  networking.hostId = "91312b0a";

  # 128G tmpfs, 128G RAM (+zram swap)
  fileSystems."/nix/var/nix/builds".options = [ "size=128G" ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "usbhid"
  ];
}
