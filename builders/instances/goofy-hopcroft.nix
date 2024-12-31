{
  imports = [
    ../profiles/hetzner-rx220.nix
  ];

  nix.settings = {
    cores = 2;
    max-jobs = 40;
  };

  networking = {
    hostName = "goofy-hopcroft";
    domain = "builders.nixos.org";
    useDHCP = false;
  };

  systemd.network = {
    enable = true;
    networks = {
      "30-enP3p2s0f0" = {
        matchConfig = {
          MACAddress = "74:56:3c:8c:01:a9";
          Type = "ether";
        };
        linkConfig.RequiredForOnline = true;
        networkConfig.Description = "WAN";
        address = [
          "135.181.225.104/26"
          "2a01:4f9:3071:2d8b::1/64"
        ];
        routes = [
          { Gateway = "135.181.225.65"; }
          { Gateway = "fe80::1"; }
        ];
      };
    };
  };

  system.stateVersion = "24.11";
}
