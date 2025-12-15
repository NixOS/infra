{
  systemd.network = {
    enable = true;
    networks = {
      "30-enp35s0" = {
        matchConfig = {
          MACAddress = "a8:a1:59:04:71:f5";
          Type = "ether";
        };
        address = [
          "46.4.89.205/27"
          "2a01:4f8:212:41c9::1/64"
        ];
        routes = [
          { Gateway = "46.4.89.193"; }
          { Gateway = "fe80::1"; }
        ];
        vlan = [
          "vlan4000"
        ];
        networkConfig.Description = "WAN";
        linkConfig.RequiredForOnline = true;
      };
    };
  };
}
