{
  boot = {
    grubDevice = "/dev/sda";
    initrd = {
      extraKernelModules = ["3w_xxxx"];
    };
    kernelModules = ["kvm-intel"];
    kernelPackages = pkgs: pkgs.kernelPackages_2_6_25;
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
    zabbixAgent = {
      enable = true;
      server = "192.168.1.5";
    };
  };

  networking = {
    hostName = ""; # obtain from DHCP server
  };

  environment = {
    nix = pkgs: pkgs.nixNoBDB;
  };
}
