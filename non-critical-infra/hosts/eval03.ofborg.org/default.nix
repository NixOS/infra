{ inputs, ... }:
{
  imports = [
    inputs.srvos.nixosModules.hardware-hetzner-cloud-arm
    ../../modules/ofborg/builder.nix
    ../../modules/hydra/builder.nix
    ./hardware.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;

  networking = {
    hostName = "ofborg-eval03";
    domain = "ofborg.org";
    hostId = "007f0203";
  };

  disko.devices = import ./disko.nix;

  systemd.network.networks."10-uplink" = {
    matchConfig.MACAddress = "96:00:03:f4:25:ed";
    address = [
      "37.27.189.4/32"
      "2a01:4f9:c012:e37b::1/64"
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

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };

  system.stateVersion = "24.11"; # Did you read the comment?

  sops.secrets = {
    "ofborg/builder-rabbitmq-password" = {
      owner = "ofborg-builder";
      restartUnits = [ "ofborg-builder.service" ];
      sopsFile = ../../secrets/ofborg.eval03.ofborg.org.yml;
    };
    "harmonia/secret" = {
      owner = "harmonia";
      restartUnits = [ "harmonia.service" ];
      sopsFile = ../../secrets/ofborg.eval03.ofborg.org.yml;
    };
  };
}
