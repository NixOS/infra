{pkgs, config, ...}:

{
  boot = {
    grubDevice = "/dev/sda";
    initrd = {
      extraKernelModules = ["3w_xxxx"];
    };
    kernelModules = ["kvm-intel"];
    kernelPackages = pkgs.kernelPackages_2_6_29;
    copyKernels = true;
  };

  fileSystems = [
    { mountPoint = "/";
      label = "nixos";
      options = "noatime";
    }
  ];

  swapDevices = [
    { label = "swap"; }
  ];

  nix = {
    maxJobs = 2;
    extraOptions = ''
      build-max-silent-time = 3600
    '';
  };
  
  services = {
    sshd = {
      enable = true;
    };
    zabbixAgent = {
      enable = true;
      server = "192.168.1.5";
    };
    cron = {
      systemCronJobs = [
        "15 03 * * * root ${pkgs.nixUnstable}/bin/nix-collect-garbage --max-atime $(date +\\%s -d '2 weeks ago') > /var/log/gc.log 2>&1"
      ];
    };
  };

  networking = {
    hostName = ""; # obtain from DHCP server
  };
}
