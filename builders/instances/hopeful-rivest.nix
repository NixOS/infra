{
  imports = [
    ../profiles/hetzner-rx170.nix
  ];

  # 2/80 cores remain spare
  nix.settings = {
    cores = 26;
    max-jobs = 3;
  };

  services.hydra-queue-builder-dev.mandatoryFeatures = [ "big-parallel" ];

  networking = {
    hostName = "hopeful-rivest";
    domain = "builders.nixos.org";
    useDHCP = false;
  };

  systemd.network = {
    enable = true;
    networks = {
      "30-eno1" = {
        matchConfig = {
          MACAddress = "74:56:3c:4e:d9:af";
          Type = "ether";
        };
        linkConfig.RequiredForOnline = true;
        networkConfig.Description = "WAN";
        address = [
          "135.181.230.86/26"
          "2a01:4f9:3080:388f::1/64"
        ];
        routes = [
          { Gateway = "135.181.230.65"; }
          { Gateway = "fe80::1"; }
        ];
      };
    };
  };

  system.stateVersion = "24.11";
}
