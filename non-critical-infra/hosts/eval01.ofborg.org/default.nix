{ inputs, ... }:

{
  imports = [
    inputs.srvos.nixosModules.hardware-hetzner-cloud-arm
    ../../modules/ofborg/evaluator.nix
    ./hardware.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;

  networking = {
    hostName = "ofborg-eval01";
    domain = "ofborg.org";
    hostId = "007f0201";
  };

  disko.devices = import ./disko.nix;

  systemd.network.networks."10-uplink" = {
    matchConfig.MACAddress = "96:00:03:f4:25:ec";
    address = [
      "95.217.15.9/32"
      "2a01:4f9:c012:cf00::1/64"
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

  sops.secrets."ofborg/mass-rebuilder-rabbitmq-password" = {
    owner = "ofborg-mass-rebuilder";
    restartUnits = [ "ofborg-mass-rebuilder.service" ];
    sopsFile = ../../secrets/ofborg.eval01.ofborg.org.yml;
  };
}
