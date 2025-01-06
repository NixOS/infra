{ config, ... }:

{
  imports = [
    ../common.nix
    ./boot.nix
    ./disko.nix
    ./network.nix

    ./grafana.nix
    ./nginx.nix
    ./nixos-metrics.nix
    ./prometheus

    ../../modules/hydra-mirror.nix
    ../../modules/rfc39.nix
    ../../modules/tarball-mirror.nix
  ];

  networking = {
    hostName = "pluto";
    domain = "nixos.org";
    hostId = "e4c9bd10";
  };

  age.secrets.pluto-backup-ssh-key.file = ../secrets/pluto-backup-ssh-key.age;
  age.secrets.pluto-backup-secret.file = ../secrets/pluto-backup-secret.age;

  services.backup = {
    user = "u391032-sub2";
    host = "u391032.your-storagebox.de";
    hostPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
    port = 23;
    sshKey = config.age.secrets.pluto-backup-ssh-key.path;
    secretPath = config.age.secrets.pluto-backup-secret.path;
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "23.11";
}
