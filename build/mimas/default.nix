{
  pkgs,
  ...
}:

{
  imports = [
    ../common.nix
    ../hydra.nix
    ../hydra-proxy.nix
    ../hydra-scaler.nix
    ../packet-importer.nix
    ./boot.nix
    ./network.nix
  ];

  disko.devices = import ./disko.nix;

  networking = {
    hostName = "mimas";
    domain = "nixos.org";
    hostId = "aba92093";
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # garbage collection
  nix.gc = {
    automatic = true;
    options = ''--max-freed "$((400 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';
    dates = "03,09,15,21:15";
  };

  # gc outputs as well, since they are served from the cache
  nix.settings.gc-keep-outputs = false;

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "24.11";
}
