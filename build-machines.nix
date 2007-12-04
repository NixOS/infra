{
  boot = {
    grubDevice = "/dev/sda";
    initrd = {
      extraKernelModules = ["3w_xxxx"];
    };
  };

  fileSystems = [
    { mountPoint = "/";
      label = "nixos";
    }
  ];

  swapDevices = [
    { label = "swap"; }
  ];

  nix = {
    maxJobs = 2;
  };
  
  services = {
    sshd = {
      enable = true;
    };
  };

  networking = {
    hostName = ""; # obtain from DHCP server
  };
}
