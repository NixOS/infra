{ lib, pkgs, ... }:
  {
    boot = {
      loader = {
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
        "console=ttyAMA0,115200"
      ];
      kernelPackages = pkgs.linuxPackages_4_14;      
    };
    networking = {
      hostName = "builder-t2a-1";
      dhcpcd.enable = false;
      defaultGateway = {
        address = "147.75.65.53";
        interface = "bond0";
      };
      defaultGateway6 = {
        address = "2604:1380:0:d600::";
        interface = "bond0";
      };
      nameservers = [
        "147.75.207.207"
        "147.75.207.208"
      ];
      bonds = {
        bond0 = {
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
      };
    };
    networking.interfaces.bond0 = {
      useDHCP = false;
      ipv4 = {
        routes = [
          {
            address = "10.0.0.0";
            prefixLength = 8;
            via = "10.99.98.128";
          }
        ];
        addresses = [
          {
            address = "147.75.65.54";
            prefixLength = 30;
          }
          {
            address = "10.99.98.129";
            prefixLength = 31;
          }
        ];
      };
      ipv6 = {
        addresses = [
          {
            address = "2604:1380:0:d600::1";
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
    nix = {
      maxJobs = 96;
      buildCores = 4;
    };
    nixpkgs = {
      system = "aarch64-linux";
    };
    system.stateVersion = lib.mkForce "18.03";
  }
