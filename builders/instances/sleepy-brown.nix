{
  imports = [
    ../profiles/hetzner-ax101r.nix
  ];

  nix.settings = {
    cores = 24;
    max-jobs = 4;
    system-features = [ "big-parallel" ];
  };

  networking = {
    hostName = "sleepy-brown";
    domain = "builders.nixos.org";
    useDHCP = false;
  };

  systemd.network = {
    enable = true;
    networks = {
      "30-enp193s0f0np0" = {
        matchConfig = {
          MACAddress = "9c:6b:00:4e:fd:2d";
          Type = "ether";
        };
        linkConfig.RequiredForOnline = true;
        networkConfig.Description = "WAN";
        address = [
          "162.55.130.51/26"
          "2a01:4f8:271:5c14::1/64"
        ];
        routes = [
          { Gateway = "162.55.130.1"; }
          { Gateway = "fe80::1"; }
        ];
      };
    };
  };

  system.stateVersion = "24.11";
}
