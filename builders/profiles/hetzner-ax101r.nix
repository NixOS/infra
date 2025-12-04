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

  fileSystems."/nix/var/nix/builds" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "huge=within_size"
      "mode=0700"
      "nosuid"
      "nodev"
    ]
    # 128G tmpfs, 128G RAM (+zram swap) for standard builders
    # 160GB tmpfs, 96 GB RAM (+zram swap) for big-parallel builders
    ++ (
      if lib.elem "big-parallel" config.nix.settings.system-features then
        [ "size=160G" ]
      else
        [ "size=128G" ]
    );
  };

  boot.initrd.availableKernelModules = [
    "nvme"
    "usbhid"
  ];
}
