{
  config,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ./hardware.nix
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.hardware-hetzner-online-amd
    ../../../modules/rasdaemon.nix
    ../../modules/common.nix
    ../../modules/draupnir.nix
    ../../modules/backup.nix
    ../../modules/element-web.nix
    ../../modules/limesurvey.nix
    ../../modules/lasuite-meet.nix
    ../../modules/matrix-synapse.nix
    ../../modules/owncast.nix
    ../../modules/vaultwarden.nix
    ./nixpkgs-swh.nix
  ];

  fileSystems."/boot-1" = {
    device = "/dev/disk/by-uuid/9299-8E8E";
    fsType = "vfat";
  };

  fileSystems."/boot-2" = {
    device = "/dev/disk/by-uuid/9297-573C";
    fsType = "vfat";
  };

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.mirroredBoots = lib.mkForce [
    {
      path = "/boot-1";
      devices = [ "/dev/disk/by-id/nvme-SAMSUNG_MZQL23T8HCLS-00A07_S64HNJ0T508051" ];
    }
    {
      path = "/boot-2";
      devices = [ "/dev/disk/by-id/nvme-SAMSUNG_MZQL23T8HCLS-00A07_S64HNJ0T508053" ];
    }
  ];

  networking = {
    hostName = "caliban";
    domain = "nixos.org";
    hostId = "745b334a";
  };

  disko.devices = import ./disko.nix;

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  networking.firewall.allowedUDPPorts = [ ];

  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f9:5a:186c::2";

  sops.secrets.storagebox-ssh-key = {
    sopsFile = ../../secrets/storagebox-ssh-key.caliban;
    format = "binary";
    path = "/var/keys/storagebox-ssh-key";
    mode = "0600";
    owner = "root";
    group = "root";
  };

  sops.secrets.backup-secret = {
    sopsFile = ../../secrets/backup-secret.caliban;
    format = "binary";
    path = "/var/keys/borg-secret";
    mode = "0600";
    owner = "root";
    group = "root";
  };

  services.backup = {
    user = "u391032-sub3";
    host = "u391032-sub3.your-storagebox.de";
    hostPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
    port = 23;
    sshKey = config.sops.secrets.storagebox-ssh-key.path;
    secretPath = config.sops.secrets.backup-secret.path;
  };

  system.stateVersion = "23.05";

}
