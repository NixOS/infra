# Configuration for the Dell PowerEdge 1950 build machines.

{pkgs, config, ...}:

{
  boot = {
    grubDevice = "/dev/sda";
    initrd = {
      extraKernelModules = ["uhci_hcd" "ehci_hcd" "ata_piix" "mptsas" "usbhid" "ext4"];
    };
    kernelModules = ["acpi-cpufreq" "kvm-intel"];
    kernelPackages = pkgs: pkgs.kernelPackages_2_6_28;
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
    maxJobs = 8;
    extraOptions = ''
      build-max-silent-time = 3600
    '';
  };
  
  services = {
    sshd = {
      enable = true;
    };
    /*
    zabbixAgent = {
      enable = true;
      server = "192.168.1.5";
    };
    */
    cron = {
      systemCronJobs = [
        "15 03 * * * root ${pkgs.nixUnstable}/bin/nix-collect-garbage --max-freed $((32 * 1024**3)) > /var/log/gc.log 2>&1"
      ];
    };
  };

  networking = {
    hostName = ""; # obtain from DHCP server
  };

  environment.extraPackages = [pkgs.emacs];
}
