{
  systemd.network = {
    enable = true;
    networks = {
      "30-enp5s0" = {
        matchConfig = {
          MACAddress = "c8:7f:54:67:bd:31";
          Type = "ether";
        };
        linkConfig.RequiredForOnline = true;
        networkConfig.Description = "WAN";
        address = [
          "37.27.99.100/26"
          "2a01:4f9:3070:15e0::1/64"
        ];
        routes = [
          { Gateway = "37.27.99.65"; }
          { Gateway = "fe80::1"; }
        ];
      };
    };
  };
}
