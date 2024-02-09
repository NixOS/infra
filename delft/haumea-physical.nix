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
        networking = {
          defaultGateway = { address = "46.4.89.193"; interface = "eth0"; };
          defaultGateway6 = { address = "fe80::1"; interface = "eth0"; };
          interfaces.eth0 = {
            ipv4.addresses = [
              { address = "46.4.89.205"; prefixLength = 27; }
            ];
            ipv6.addresses = [
              { address = "2a01:4f8:173:a02::"; prefixLength = 64; }
            ];
          };
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
          ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="a8:a1:59:04:71:f5", NAME="eth0"
        '';
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

          nix.maxJobs = lib.mkDefault 16;
          powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
        })
      ];
    }
  ];
}
