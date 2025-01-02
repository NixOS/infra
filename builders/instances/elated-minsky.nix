{
  imports = [
    ../profiles/hetzner-ax101r.nix
  ];

  nix.settings = {
    cores = 2;
    max-jobs = 48;
  };

  networking = {
    hostName = "elated-minsky";
    domain = "builders.nixos.org";
    useDHCP = false;
  };

  systemd.network = {
    enable = true;
    networks = {
      "30-enp193s0f0np0" = {
        matchConfig = {
          MACAddress = "9c:6b:00:4e:1a:6a";
          Type = "ether";
        };
        linkConfig.RequiredForOnline = true;
        networkConfig.Description = "WAN";
        address = [
          "167.235.95.99/26"
          "2a01:4f8:2220:1b03::1/64"
        ];
        routes = [
          { Gateway = "167.235.95.65"; }
          { Gateway = "fe80::1"; }
        ];
      };
    };
  };

  system.stateVersion = "24.11";
}
