{ config, lib, pkgs, ... }:
{

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.openssh.enable = true;

  networking.hostId = "e81bb594";
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "18.09"; # Did you read the comment?

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "firewire_ohci" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.kernelModules = [ "kvm-intel" ];

  # The broadcom_sta is commented and wl, cfg80211 are blacklisted
  # to prevent spamming of wl_cfg80211 dmesg errors.
  boot.blacklistedKernelModules = [ "wl" "cfg80211" "mac80211" ];
  #boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];

  fileSystems."/" =
    { device = "rpool/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-label/swap"; }
    ];

  nix.maxJobs = lib.mkDefault 4;
}
