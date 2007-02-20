{
  boot = {
    grubDevice = "/dev/hda";
  };

  networking = {
    hostName = "vm-nix-01";
  };

  fileSystems = [
    { mountPoint = "/";
      label = "nixos";
    }
  ];

  swapDevices = [
    { label = "swap"; }
  ];
  
  services = {
    sshd = {
      enable = true;
    };
  };
}
