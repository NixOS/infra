{
  systemd.network = {
    enable = true;
    netdevs = {
      "20-vlan4000" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "vlan4000";
        };
        vlanConfig.Id = 4000;
      };
    };
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
      "30-vlan4000" = {
        matchConfig.Name = "vlan4000";
        linkConfig = {
          MTUBytes = "1400";
          RequiredForOnline = "routable";
        };
        address = [
          "10.0.40.1/31"
        ];
      };
    };
  };
}
