{ lib, pkgs, ... }:
  {
    boot = {
      loader = {
        systemd-boot.enable = lib.mkForce false;
        grub = {
          enable = true;
          version = 2;
          efiSupport = true;
          device = "nodev";
          efiInstallAsRemovable = true;
          font = null;
          splashImage = null;
          extraConfig = ''
            serial
            terminal_input serial console
            terminal_output serial console
          '';
        };
        efi = {
          efiSysMountPoint = "/boot/efi";
          canTouchEfiVariables = lib.mkForce false;
        };
      };
      initrd = {
        availableKernelModules = [
          "ahci"
          "pci_thunder_ecam"
        ];
      };
      kernelParams = [
        "cma=0M"
        "biosdevname=0"
        "net.ifnames=0"
        "console=ttyAMA0"
      ];
      kernelPackages = pkgs.linuxPackages_4_14;
    };
   
    networking.hostId = "6150845b";
    networking.hostName = "packet-t2a-2";
    networking.dhcpcd.enable = false;
    networking.defaultGateway = {
      address = "147.75.79.197";
      interface = "bond0";
    };
    networking.defaultGateway6 = {
      address = "2604:1380:0:d600::4";
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
      interfaces = [ "eth0" "eth1" ];
    };
    networking.interfaces.bond0 = {
      useDHCP = false;
      ipv4 = {
        routes = [
          {
            address = "10.0.0.0";
            prefixLength = 8;
            via = "10.99.98.132";
          }
        ];
        addresses = [
          {
            address = "147.75.79.198";
            prefixLength = 30;
          }
          {
            address = "10.99.98.133";
            prefixLength = 31;
          }
        ];
      };
      ipv6 = {
        addresses = [
          {
            address = "2604:1380:0:d600::5";
            prefixLength = 127;
          }
        ];
      };
    };
    fileSystems = {
      "/" = {
        device = "/dev/sda2";
        fsType = "ext4";
      };
      "/boot/efi" = {
        device = "/dev/sda1";
        fsType = "vfat";
      };
    };
    services.openssh.enable = true;
    nix = {
      maxJobs = 96;
      buildCores = 4;
    };
    nixpkgs = {
      system = "aarch64-linux";
      config = {
        allowUnfree = true;
      };
    };
    system.stateVersion = lib.mkForce "18.03";    
  }

