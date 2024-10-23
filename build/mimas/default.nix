{
  imports = [
    ../common.nix
    ./boot.nix
    ./network.nix
  ];

  disko.devices = import ./disko.nix;

  networking = {
    hostName = "mimas";
    domain = "nixos.org";
    hostId = "aba92093";
  };

  system.stateVersion = "24.11";
}
