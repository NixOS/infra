{
  imports = [
    ../common.nix
    ./boot.nix
    ./network.nix
    ./postgresql.nix
    ./zrepl.nix
  ];

  disko.devices = import ./disko.nix;

  networking = {
    hostId = "e1ce6466";
    hostName = "titan";
    domain = "nixos.org";
  };

  services.zfs.autoScrub.enable = true;

  system.stateVersion = "25.11";
}
