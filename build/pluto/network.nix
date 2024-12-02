{
  systemd.network = {
    enable = true;
    networks = {
      "30-enp5s0" = {
        matchConfig = {
          MACAddress = "08:bf:b8:18:2e:23";
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
