{ config, pkgs, lib, inputs, ... }:

{
  imports =
    [
      ./hardware.nix
      inputs.srvos.nixosModules.server
      inputs.srvos.nixosModules.hardware-hetzner-online-amd
      ../../modules/common.nix
      ../../modules/first-time-contribution-tagger.nix
      ../../modules/backup.nix
      ../../modules/element-web.nix
      ../../modules/matrix-synapse.nix
      ../../modules/owncast.nix
      ../../modules/vaultwarden.nix
      ./limesurvey-tmp.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.loader.grub.mirroredBoots = [
    { path = "/boot-1"; devices = [ "/dev/disk/by-id/nvme-SAMSUNG_MZQL23T8HCLS-00A07_S64HNJ0T508051" ]; }
    { path = "/boot-2"; devices = [ "/dev/disk/by-id/nvme-SAMSUNG_MZQL23T8HCLS-00A07_S64HNJ0T508053" ]; }
  ];
  boot.loader.grub.useOSProber = true;

  networking = {
    hostName = "caliban";
    domain = "nixos.org";
    hostId = "745b334a";
  };

  disko.devices = import ./disko.nix;

  networking.firewall.allowedTCPPorts = [ 80 443 ];
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
    user = "u371748";
    host = "u371748.your-storagebox.de";
    hostPublicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";
    port = 23;
    sshKey = config.sops.secrets.storagebox-ssh-key.path;
    secretPath = config.sops.secrets.backup-secret.path;
    quota = "90G"; # of 100G
  };

  system.stateVersion = "23.05";

}

