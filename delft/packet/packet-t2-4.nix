{ lib, pkgs, ... }:
  {
    networking.hostId = "ba66ccd0";
    networking.hostName = "packet-t2-4";
    networking.dhcpcd.enable = false;
    networking.defaultGateway = {
      address = "147.75.98.144";
      interface = "bond0";
    };
    networking.defaultGateway6 = {
      address = "2604:1380:0:d600::2";
      interface = "bond0";
    };
    networking.nameservers = [
      "147.75.207.207"
      "147.75.207.208"
    ];
    networking.bonds.bond0 = {
      driverOptions = {
        mode = "802.3ad";
        xmit_hash_policy = "layer3+4";
        lacp_rate = "fast";
        downdelay = "200";
        miimon = "100";
        updelay = "200";
      };
      interfaces = [
        "enp2s0"
        "enp2s0d1"
      ];
    };
    networking.interfaces.bond0 = {
      useDHCP = true;
      ipv4 = {
        routes = [
          {
            address = "10.0.0.0";
            prefixLength = 8;
            via = "10.99.98.130";
          }
        ];
        addresses = [
          {
            address = "147.75.98.145";
            prefixLength = 31;
          }
          {
            address = "10.99.98.131";
            prefixLength = 31;
          }
        ];
      };
      ipv6 = {
        addresses = [
          {
            address = "2604:1380:0:d600::3";
            prefixLength = 127;
          }
        ];
      };
    };

    nixpkgs.config.allowUnfree = true;
    boot.initrd.availableKernelModules = [
      "xhci_pci"
      "ehci_pci"
      "ahci"
      "megaraid_sas"
      "sd_mod"
    ];
    boot.kernelPackages = pkgs.linuxPackages_4_14;
    boot.kernelModules = [
      "kvm-intel"
    ];
    boot.kernelParams = [
      "console=ttyS1,115200n8"
    ];
    boot.extraModulePackages = [];
    hardware.enableAllFirmware = true;
    nix.maxJobs = 48;
    nix.buildCores = lib.mkForce 4;
    boot.loader.grub.devices = [
      "/dev/sda"
    ];
    boot.loader.grub.extraConfig = ''
      serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
      terminal_output serial console
      terminal_input serial console
    '';
    fileSystems = {
      "/" = {
        label = "nixos";
        fsType = "ext4";
      };
    };
    swapDevices = [
      { label = "swap"; }
    ];
  }
