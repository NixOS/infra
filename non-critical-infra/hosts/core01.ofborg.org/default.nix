{ inputs, ... }:

{
  imports = [
    inputs.srvos.nixosModules.hardware-hetzner-cloud
    ../../modules/ofborg/common.nix
    ../../modules/ofborg/github-tokens.nix
    ./nginx.nix
    ./rabbitmq.nix
    # ofborg.org landingpage
    # ./website.nix
    # Accepts webhooks from GitHub
    ./github-webhook-receiver.nix
    # Checks wheter a PR event is interesting to us
    ./evaluation-filter.nix
    # Handles incoming comments
    ./github-comment-filter.nix
    # Receives logs from builders
    ./log-message-collector.nix
    # Posts to GitHub
    ./github-comment-poster.nix
    # LogApi and LogViewer
    ./log-viewer.nix
  ];
  # TODO backups

  # Bootloader.
  boot.loader.grub.enable = true;

  networking = {
    hostName = "ofborg-core01";
    domain = "ofborg.org";
    hostId = "007f0101";
  };

  disko.devices = import ./disko.nix;

  systemd.network.networks."10-uplink" = {
    matchConfig.MACAddress = "96:00:03:ea:fa:62";
    address = [
      "138.199.148.47/32"
      "2a01:4f8:c012:cda4::1/64"
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

  system.stateVersion = "24.11"; # Did you read the comment?
}
