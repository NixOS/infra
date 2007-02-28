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
  
  networking = {
    useDHCP = false;
    interfaces = [
      { name = "eth0";
        ipAddress = "192.168.1.14";
      }
    ];
    defaultGateway = "192.168.1.5";
    nameservers = ["130.161.158.4" "130.161.33.17" "130.161.180.1"];
  };
  
  services = {
    sshd = {
      enable = true;
    };
  };

}
