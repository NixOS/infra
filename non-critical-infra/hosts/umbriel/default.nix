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
    inputs.srvos.nixosModules.hardware-hetzner-cloud-arm
    ../../modules/common.nix
    ../../modules/backup.nix
    ../../modules/mailserver
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = lib.mkForce 5;
  boot.loader.efi.efiSysMountPoint = "/efi";

  # workaround because the console defaults to serial
  boot.kernelParams = [ "console=tty" ];

  services.cloud-init.enable = false;

  networking = {
    hostName = "umbriel";
    domain = "nixos.org";
    hostId = "36d29388";
  };

  disko.devices = import ./disko.nix;

  systemd.network.networks."10-uplink" = {
    matchConfig.MACAddress = "96:00:02:b5:f8:99";
    address = [
      "37.27.20.162/32"
      "2a01:4f9:c011:8fb5::1/64"
    ];
    routes = [
      { Gateway = "fe80::1"; }
      {
        Gateway = "172.31.1.1";
        GatewayOnLink = true;
      }
    ];
    linkConfig.RequiredForOnline = "routable";
  };

  # How to generate:
  #
  #   $ cd non-critical-infra
  #   $ SECRET_PATH=secrets/storagebox-ssh-key.umbriel
  #   $ ssh-keygen -t ed25519 -f "$SECRET_PATH" -P "" -C root@umbriel
  #   $ sops encrypt --in-place "$SECRET_PATH"
  #   $ rm "$SECRET_PATH".pub
  #
  # Next, deploy this secret, ssh to the machine and install the secret on the storagebox:
  #
  #   $ ssh-keygen -f /var/keys/storagebox-ssh-key -y | ssh -o "UserKnownHostsFile=/dev/null" -p23 u391032-sub4@u391032-sub4.your-storagebox.de install-ssh-key
  sops.secrets.storagebox-ssh-key = {
    sopsFile = ../../secrets/storagebox-ssh-key.umbriel;
    format = "binary";
    path = "/var/keys/storagebox-ssh-key";
    mode = "0600";
    owner = "root";
    group = "root";
  };

  # How to generate:
  #
  #   $ cd non-critical-infra
  #   $ SECRET_PATH=secrets/backup-secret.umbriel
  #   $ pwgen -s 64 1 > "$SECRET_PATH"
  #   $ sops encrypt --in-place "$SECRET_PATH"
  sops.secrets.backup-secret = {
    sopsFile = ../../secrets/backup-secret.umbriel;
    format = "binary";
    path = "/var/keys/borg-secret";
    mode = "0600";
    owner = "root";
    group = "root";
  };

  services.backup = {
    user = "u391032-sub4";
    host = "u391032-sub4.your-storagebox.de";
    hostPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
    port = 23;
    sshKey = config.sops.secrets.storagebox-ssh-key.path;
    secretPath = config.sops.secrets.backup-secret.path;
  };

  system.stateVersion = "23.05";
}
