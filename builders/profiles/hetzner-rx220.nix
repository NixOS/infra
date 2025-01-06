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

  # 96G for build roots, 160G for working memory
  boot.tmp = {
    useTmpfs = true;
    #  96G tmpfs, 160G RAM for standard builders
    # 128G tmpfs, 128G RAM for big parallel builders
    tmpfsSize = if lib.elem "big-parallel" config.nix.settings.system-features then "128G" else "96G";
  };

  boot.initrd.availableKernelModules = [
    "nvme"
    "usbhid"
  ];
}
