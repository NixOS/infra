{ config, pkgs, ... }:
let
  exporter = pkgs.fetchFromGitHub {
    owner = "grahamc";
    repo = "prometheus-packet-spot-market-price-exporter";
    rev = "48ec8f06ae8fb358cf11e85c6ec9a87419ddb58f";
    sha256 = "sha256-VI44jSKw7lxILhRQAjWO5gCHV5gkpicWAUKECvnBAxg=";
  };
in {
  deployment.keys.prometheus-packet-spot-market-price-exporter = {
    keyFile = /home/deploy/src/nixos-org-configurations/keys/prometheus-packet-spot-market-price-exporter-config.json;
    user = "spot-price-exporter";
  };

  users.extraUsers.spot-price-exporter = {
    description = "Prometheus Packet Spot Market Price Exporter";
  };

  systemd.services.prometheus-packet-spot-market-price-exporter = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      User = "spot-price-exporter";
      Group = "keys";
      Restart = "always";
      RestartSec = "60s";
      PrivateTmp =  true;
    };

    path = [
      (pkgs.python3.withPackages (p: [ p.prometheus_client p.requests ]))
    ];

    script = "exec python3 ${exporter}/scrape.py /run/keys/prometheus-packet-spot-market-price-exporter";
  };
}