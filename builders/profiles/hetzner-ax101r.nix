{
  config,
  lib,
  ...
}:

{
  imports = [
    ../boot/efi-grub.nix
  ];

  disko.devices = import ../disk-layouts/efi-zfs-raid0.nix { };
  boot.supportedFilesystems.zfs = true;
  networking.hostId = "91312b0a";

  # 128G tmpfs, 128G RAM (+zram swap) for standard builders
  # 160GB tmpfs, 96 GB RAM (+zram swap) for big-parallel builders
  fileSystems."/nix/var/nix/builds".options =
    if lib.elem "big-parallel" config.nix.settings.system-features then
      [ "size=160G" ]
    else
      [ "size=128G" ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "usbhid"
  ];
}
