{
  boot.loader = {
    efi.canTouchEfiVariables = false;
    grub = {
      enable = true;
      configurationLimit = 5;
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
}
