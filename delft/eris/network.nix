{
  systemd.network = {
    enable = true;
    networks = {
      "30-enp0s31f6" = {
        matchConfig = {
          MACAddress = "90:1b:0e:91:c3:67";
          Type = "ether";
        };
        linkConfig.RequiredForOnline = true;
        networkConfig.Description = "WAN";
        address = [
          "138.201.32.77/26"
          "2a01:4f8:171:33cc::1/64"
        ];
        routes = [ {
          routeConfig.Gateway = "138.201.32.65";
        } {
          routeConfig.Gateway = "fe80::1";
        } ];
      };
    };
  };
}
