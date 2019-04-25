{ lib, config, ... }: {
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sdhci_pci" ];
  boot.kernelModules = [ "kvm-intel" "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];

  boot.supportedFilesystems = [ "zfs" ];

  nixpkgs.config.allowUnfree = true;

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
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  networking.hostId = "03156864";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "mac3";
  services.openssh.enable = true;

  system.stateVersion = "18.09"; # Did you read the comment?

  users.extraUsers.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDI6/qMXX80oWm+NyftRw45D+mRJwJQ6gexkUhp1OgZc3MuW6Zm2RO2IZHEjJLSMUndZebbznPmPPM58VxiyQnRYH2+hn+qCrwSsyCUxA8Gz6PpxeaeUMlpbsuXOPFbvBraDZEqIvx/gIK849nIahGz3EcfaY73lVRP+MrrVHBGyQmaOLoNfzrJp8rZfLqokQQXmG1d3DzjkIi87TZLgrdxQewpk/4eKBKf8FDnEYeV3ood78SPa3syS48al99Q7e8JyAEZJfyCQkUSUxgSizU5+se1A5seDJg2Vsqef1Ah23g/lTtSn93vtjjLvObvMJTSplBO8ttG/3ylIewWYER/"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDY8wRHQtq9uBzdiAYzpSNmF+nmIHmW+AOeBTDNmdva+CFGIBbB56q7w6GCOhfXs8edrPY4qOcQGaOD0ussIvHnqkVfw8e6CbxnpXKeAuIz7+1V72AhLPzOkif4yPrI6tSYF5nvzq6U4Yk1qFnXiLQjkA1s4EcZH6V0KbHMsu7Mtv3Irspdn8KUI3j2UwZcssFu1EuLHhLNussziRQK9tOg9ixb0U1WXuUJn7Noh9odTAsAt6jLFdr5eN/IINgC9WQqvY/W94Tc2/z5TWR7z382pEkMBR/3sf+nYKA82069tagkyrtJ/YXi00CWU4vjpnMvwPEYcmtCddfCPi8ZIUrn grahamc@Morbo"
  ];
}
