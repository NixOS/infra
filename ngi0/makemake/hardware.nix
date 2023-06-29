{ lib, ... }:

{
  system.stateVersion = lib.mkDefault "23.05";

  networking = {
    defaultGateway = {
      address = "116.202.113.193";
      interface = "eth0";
    };
    defaultGateway6 = { address = "fe80::1"; interface = "eth0"; };
    interfaces.eth0 = {
      ipv4.addresses = [
        { address = "116.202.113.248"; prefixLength = 26; }
      ];
      ipv6.addresses = [
        { address = "2a01:4f8:231:4187::"; prefixLength = 64; }
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
    ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="70:85:c2:f4:7d:27", NAME="eth0"
  '';

  boot.initrd.availableKernelModules = [ "ahci" "nvme" ];
  boot.kernelModules = [ "kvm-amd" ];

  nix.maxJobs = lib.mkDefault 16;
}
