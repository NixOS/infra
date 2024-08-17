{
  boot = {
    supportedFilesystems = [ "zfs" ];
    loader = {
      efi.canTouchEfiVariables = false;
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        mirroredBoots = [
          {
            devices = [ "nodev" ];
            path = "/efi/a";
          }
          {
            devices = [ "nodev" ];
            path = "/efi/b";
          }
        ];
      };
    };
  };
}
