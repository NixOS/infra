{config, pkgs, ...}:

{
  boot = {
    initrd = {
      extraKernelModules = [ "uhci_hcd" "ehci_hcd" "ata_piix" "mptsas" "usbhid" "ext4" ];
    };
    kernelModules = [ "acpi-cpufreq" "kvm-intel" ];
    kernelPackages = pkgs.kernelPackages_2_6_28;
    grubDevice = "/dev/sda";
  };

  fileSystems = [
    { mountPoint = "/"; 
      label = "nixos";
    }
  ];
 
  swapDevices = [
    { label = "swap" ; }
  ];

  nix = {
    maxJobs = 8;
  };

  networking = {
    hostName = "hydra";
    domain = "buildfarm";
  };

  services = {

    sshd = {
      enable = true;
    };
      
  };
}
