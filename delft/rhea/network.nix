{
  networking.hostId = "9cd372da";

  systemd.network = {
    enable = true;
    networks."40-enp7s0" = {
      matchConfig = {
        MACAddress = "50:eb:f6:22:f0:3a";
        Type = "ether";
      };
      linkConfig.RequiredForOnline = "routable";
      networkConfig.Description = "WAN";
      address = [
        "5.9.122.43/27"
        "2a01:4f8:162:71eb::/64"
      ];
      routes = [ {
        routeConfig.Gateway = "5.9.122.33";
      } {
        routeConfig.Gateway = "fe80::1";
      } ];
    };
  };
}
