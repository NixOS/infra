{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostId = "9cd372da";
  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network.networks."40-enp7s0" = {
    matchConfig = {
      MACAddress = "50:eb:f6:22:f0:3a";
    };

    addresses = [
      {
        addressConfig.Address = "5.9.122.43/27";
      }
      {
        addressConfig.Address = "2a01:4f8:162:71eb::/64";
      }
    ];
    routes = [
      {
        routeConfig.Gateway = "5.9.122.33";
      }
      {
        routeConfig.Gateway = "fe80::1";
      }
    ];

    dns = [
      "185.12.64.1"
      "185.12.64.2"
      "2a01:4ff:ff00::add:1"
      "2a01:4ff:ff00::add:2"
    ];
  };
}
