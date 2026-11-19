{
  config,
  ...
}:

{
  imports = [
    ../common.nix
    ./boot.nix
    ./network.nix

    ./grafana.nix
    ./nixos-metrics.nix
    ./nginx.nix
    ./prometheus

    ../../modules/hydra-mirror.nix
    ../../modules/rfc39.nix
    ../../modules/tarball-mirror.nix
  ];

  disko.devices = import ./disko.nix;

  networking = {
    hostId = "e1ce6466";
    hostName = "titan";
    domain = "nixos.org";
  };

  age.secrets.titan-backup-ssh-key.file = ../secrets/titan-backup-ssh-key.age;
  age.secrets.titan-backup-secret.file = ../secrets/titan-backup-secret.age;

  services.backup = {
    user = "u391032-sub2";
    host = "u391032.your-storagebox.de";
    hostPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
    port = 23;
    sshKey = config.age.secrets.titan-backup-ssh-key.path;
    secretPath = config.age.secrets.titan-backup-secret.path;
  };

  services.zfs.autoScrub.enable = true;

  system.stateVersion = "25.11";
}
