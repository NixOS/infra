# Transitional. This is the auto-generated nixops config for haumea, extracted
# into a file that we can check in and import when evaluating outside of
# nixops.

{ config, lib, pkgs, modulesPath, ... }: {
  config = {
    boot.kernelModules = [];
    networking = {
      hostName = "haumea";
      extraHosts = ''
        138.201.32.77 eris eris-unencrypted
        46.4.89.205 haumea haumea-unencrypted
        127.0.0.1 haumea-encrypted
      '';
      firewall.trustedInterfaces = [];
    };
  };
  imports = [
    {
      config = {
        users.extraUsers.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+xcwa7Oj8At7n8gHQu7UXArxCJSQZgMaspfkyLbP1j NixOps client key of haumea"
        ];
      };
      imports = [
        ({})
        ({ config, lib, pkgs, ... }:

        {
          imports =
            [ "${modulesPath}/installer/scan/not-detected.nix"
            ];

          boot.initrd.availableKernelModules = [ "ahci" "nvme" "usbhid" ];
          boot.initrd.kernelModules = [ ];
          boot.kernelModules = [ "kvm-amd" ];
          boot.extraModulePackages = [ ];

          nix.settings.max-jobs = lib.mkDefault 16;
          powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
        })
      ];
    }
  ];
}
