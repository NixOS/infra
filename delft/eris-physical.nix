# Transitional. This is the auto-generated nixops config for eris, extracted
# into a file that we can check in and import when evaluating outside of
# nixops.

{ config, lib, pkgs, modulesPath, ... }: {
  config = {
    boot.kernelModules = [];
    networking = {
      hostName = "eris";
      extraHosts = ''
        138.201.32.77 eris eris-unencrypted
        127.0.0.1 eris-encrypted
        46.4.89.205 haumea haumea-unencrypted
      '';
      firewall.trustedInterfaces = [];
    };
    system.stateVersion = ( lib.mkDefault "18.03" );
  };
  imports = [
    {
      config = {
        networking = {
          defaultGateway = "138.201.32.65";
          interfaces.eth0 = {
            ipAddress = "138.201.32.77";
            prefixLength = 26;
          };
          localCommands = ''
            ip -6 addr add '2a01:4f8:171:33cc::/64' dev 'eth0' || true
            ip -4 route change '138.201.32.64/26' via '138.201.32.65' dev 'eth0' || true
            ip -6 route add default via 'fe80::1' dev eth0 || true
          '';
          nameservers = [
            "213.133.98.98"
            "213.133.99.99"
            "213.133.100.100"
            "2a01:4f8:0:a0a1::add:1010"
            "2a01:4f8:0:a102::add:9999"
            "2a01:4f8:0:a111::add:9898"
          ];
        };
        services.udev.extraRules = ''
          ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="90:1b:0e:91:c3:67", NAME="eth0"
        '';
        users.extraUsers.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXnddtPlqCgmGK3yE48/eoUke4u2O2SIin6kUp4T1eZ NixOps client key of eris"
        ];
      };
      imports = [
        ({
          swapDevices = [
            { label = "swap1"; }
            { label = "swap2"; }
          ];
          boot.loader.grub.devices = [
            "/dev/sda"
            "/dev/sdb"
          ];
          fileSystems = {
            "/" = {
              fsType = "ext4";
              label = "root";
            };
          };
        })
        ({ config, lib, pkgs, ... }:

        {
          imports =
            [ "${modulesPath}/installer/scan/not-detected.nix"
            ];

          boot.initrd.availableKernelModules = [ "ahci" "sd_mod" ];
          boot.kernelModules = [ "kvm-intel" ];
          boot.extraModulePackages = [ ];

          nix.maxJobs = lib.mkDefault 8;
          powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
        })
      ];
    }
  ];
}
