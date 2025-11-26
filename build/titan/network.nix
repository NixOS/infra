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
          MACAddress = "9c:6b:00:1f:aa:fd";
          Type = "ether";
        };
        address = [
          "159.69.62.224/26"
          "2a01:4f8:231:e53::1/64"
        ];
        routes = [
          { Gateway = "159.69.62.193"; }
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
        networkConfig = {
          DHCP = false;
          IPv6AcceptRA = false;
        };
        linkConfig = {
          MTUBytes = "1400";
          RequiredForOnline = "routable";
        };
        address = [
          "10.0.40.3/31"
        ];
      };
    };
  };
}
