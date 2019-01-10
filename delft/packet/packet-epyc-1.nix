{
  imports = [
    ({ lib, ... }:
      {
        boot = {
          loader = {
            systemd-boot.enable = lib.mkForce false;
            grub = {
              enable = true;
              extraConfig = ''
                serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
                terminal_output serial console
                terminal_input serial console
              '';
            };
            efi = {
              efiSysMountPoint = "/boot/efi";
              canTouchEfiVariables = lib.mkForce false;
            };
          };
        };
        fileSystems = {
          "/" = {
            label = "nixos";
            fsType = "ext4";
          };
          "/boot/efi" = {
            device = "/dev/sda1";
            fsType = "vfat";
          };
        };
        swapDevices = [
          { label = "swap"; }
        ];
      })
    {
      networking.hostId = "c6721623";
    }
    {
      networking.hostName = "packet-epyc-1";
      networking.dhcpcd.enable = false;
      networking.defaultGateway = {
        address = "147.75.198.46";
        interface = "bond0";
      };
      networking.defaultGateway6 = {
        address = "2604:1380:0:d600::8";
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
          "enp1s0f0"
          "enp1s0f1"
        ];
      };
      networking.interfaces.bond0 = {
        useDHCP = false;
        ipv4 = {
          routes = [
            {
              address = "10.0.0.0";
              prefixLength = 8;
              via = "10.99.98.136";
            }
          ];
          addresses = [
            {
              address = "147.75.198.47";
              prefixLength = 31;
            }
            {
              address = "10.99.98.137";
              prefixLength = 31;
            }
          ];
        };
        ipv6 = {
          addresses = [
            {
              address = "2604:1380:0:d600::9";
              prefixLength = 127;
            }
          ];
        };
      };
    }
    {
      boot.kernelModules = [
        "dm_multipath"
        "dm_round_robin"
      ];
      services.openssh.enable = true;
    }
    ({ config, lib, pkgs, ... }:
      {
        nixpkgs.config.allowUnfree = true;
        boot.kernelPackages = pkgs.linuxPackages_4_14;
        boot.loader.grub = {
          version = 2;
          efiSupport = true;
          device = "nodev";
          efiInstallAsRemovable = true;
          extraConfig = ''
            serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
            terminal_output serial console
            terminal_input serial console
          '';
        };
        boot.initrd.availableKernelModules = [
          "xhci_pci"
          "ahci"
          "mpt3sas"
          "sd_mod"
        ];
        boot.kernelModules = [
          "kvm-amd"
        ];
        boot.kernelParams = [
          "console=ttyS1,115200n8"
        ];
        boot.extraModulePackages = [];
        hardware.enableAllFirmware = true;
        nix.maxJobs = 48;
        nix.buildCores = lib.mkForce 4;
      })
  ];
}
