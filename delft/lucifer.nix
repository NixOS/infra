{ config, lib, pkgs, ... }:

with lib;

{
  imports =
    [ ./build-machines-common.nix
      ./megacli.nix
    ];

  environment.systemPackages =
    [ pkgs.wget pkgs.megacli config.boot.kernelPackages.sysdig ];

  networking.hostName = "lucifer";
  networking.firewall.allowedTCPPorts = [ 2049 3000 4000 ];

  networking.interfaces.enx842b2b0b98f1.ipv4.addresses = singleton
    { address = "172.16.25.81";
      prefixLength = 21;
    };

  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.copyKernels = true;
  boot.initrd.kernelModules = [ "uhci_hcd" "ehci_hcd" "ata_piix" "megaraid_sas" "usbhid" ];
  boot.kernelModules = [ "acpi-cpufreq" "kvm-intel" ];
  boot.extraModulePackages = [config.boot.kernelPackages.sysdig];

  fileSystems."/".device = "/dev/disk/by-label/nixos";

  fileSystems."/fatdata" =
    { device = "/dev/fatdisk/fatdata";
      neededForBoot = true;
      options = [ "defaults" "noatime" ];
    };

  fileSystems."/nix" =
    { device = "/fatdata/nix";
      fsType = "none";
      options = [ "bind" ];
      neededForBoot = true;
    };

  fileSystems."/nix/var/nix" =
    { device = "/nix-data";
      fsType = "none";
      options = [ "bind" ];
      neededForBoot = true;
    };

  fileSystems."/data".device = "/dev/disk/by-label/data";

  users.extraUsers.rbvermaa =
    { description = "Rob Vermaas";
      home = "/home/rbvermaa";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [ (import ../ssh-keys.nix).rob ];
    };
}
