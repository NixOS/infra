{
  systemd.network = {
    enable = true;
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
        networkConfig.Description = "WAN";
        linkConfig.RequiredForOnline = true;
      };
    };
  };
}
