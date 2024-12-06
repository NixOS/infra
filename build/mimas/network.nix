{
  networking.useDHCP = false;

  systemd.network = {
    enable = true;
    networks = {
      "30-enp5s0" = {
        matchConfig = {
          MACAddress = "9c:6b:00:70:d1:f8";
          Type = "ether";
        };
        linkConfig.RequiredForOnline = true;
        networkConfig.Description = "WAN";
        address = [
          "157.90.104.34/26"
          "2a01:4f8:2220:11c8::1/64"
        ];
        routes = [
          { Gateway = "157.90.104.1"; }
          { Gateway = "fe80::1"; }
        ];
      };
    };
  };
}
