{
  imports = [
    ../common.nix
    ../hydra.nix
    ../hydra-proxy.nix
    ../hydra-queue-runner.nix
    ./boot.nix
    ./firewall.nix
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

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "24.11";
}
