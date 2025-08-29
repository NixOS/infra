{
  imports = [
    ../profiles/hetzner-rx170.nix
  ];

  nix.settings = {
    cores = 20;
    max-jobs = 10;
    system-features = [ "big-parallel" ];
  };

  # 128G RAM only, but seems to be OK in practice
  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "128G";
  };

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
