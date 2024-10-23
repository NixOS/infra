{ inputs, lib, ... }:

{
  imports = [
    ./hardware.nix
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.hardware-hetzner-cloud-arm
    ../../modules/common.nix
    ../../modules/mjolnir.nix
    ../../modules/prometheus/node-exporter.nix
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
      { routeConfig.Gateway = "fe80::1"; }
      {
        routeConfig = {
          Gateway = "172.31.1.1";
          GatewayOnLink = true;
        };
      }
    ];
    linkConfig.RequiredForOnline = "routable";
  };

  system.stateVersion = "23.05";
}
