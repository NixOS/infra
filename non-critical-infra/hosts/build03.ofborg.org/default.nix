{
  imports = [
    ../../modules/ofborg/builder.nix
    ../../modules/hydra/builder.nix
    ./hardware.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;

  networking = {
    hostName = "ofborg-build03";
    domain = "ofborg.org";
    hostId = "007f0303";
  };

  disko.devices = import ./disko.nix;

  systemd.network.networks."10-uplink" = {
    matchConfig.MACAddress = "22:33:4d:07:51:b9";
    address = [ "185.119.168.12/32" ];
    routes = [
      {
        Gateway = "91.224.148.0";
        GatewayOnLink = true;
      }
    ];
    linkConfig.RequiredForOnline = "routable";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGQ5hBVVKK72ZX+n+BVnPocx+AG5u6ht8bM++G1lhufp liberodark@gmail.com"
  ];

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  system.stateVersion = "24.11"; # Did you read the comment?

  sops.secrets = {
    "ofborg/builder-rabbitmq-password" = {
      owner = "ofborg-builder";
      restartUnits = [ "ofborg-builder.service" ];
      sopsFile = ../../secrets/ofborg.build03.ofborg.org.yml;
    };
    "harmonia/secret" = {
      owner = "harmonia";
      restartUnits = [ "harmonia.service" ];
      sopsFile = ../../secrets/ofborg.build03.ofborg.org.yml;
    };
  };
}
