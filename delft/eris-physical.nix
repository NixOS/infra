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
  };
  imports = [
    {
      config = {
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
