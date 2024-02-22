{
  imports = [
    ../common.nix
    ./boot.nix
    ./disko.nix
    ./network.nix

    ../../modules/hydra-mirror.nix
    ../../modules/netboot-serve.nix
    ../../modules/rfc39.nix
    ../../modules/tarball-mirror.nix
    ../../metrics/fastly/process-raw-nix-logs.nix
  ];

  networking = {
    hostName = "pluto";
    domain = "nixos.org";
    hostId = "e4c9bd10";
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "23.11";
}
