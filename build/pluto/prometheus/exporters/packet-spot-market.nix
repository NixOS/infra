{ config, pkgs, ... }:
let
  exporter = pkgs.fetchFromGitHub {
    owner = "grahamc";
    repo = "prometheus-packet-spot-market-price-exporter";
    rev = "b894f5dc061e2ab2d0ef101c28fce390285ad492";
    sha256 = "sha256-I2WolAAM+siE8JfZbEZ3Mmk7/XqVio/PzUKqZUYCBfE=";
  };
in {
  age.secrets.prometheus-packet-spot-market-price-exporter.file = ../../../secrets/prometheus-packet-spot-market-price-exporter.age;

  systemd.services.prometheus-packet-spot-market-price-exporter = {
    wantedBy = [
      "multi-user.target"
    ];
    after = [
      "network.target"
    ];
    serviceConfig = {
      DynamicUser = true;
      User = "spot-price-exporter";
      Group = "keys";
      Restart = "always";
      RestartSec = "60s";
      PrivateTmp =  true;
      LoadCredential = [
        "config:${config.age.secrets.prometheus-packet-spot-market-price-exporter.path}"
      ];
    };

    path = [
      (pkgs.python3.withPackages (ps: with ps; [
        prometheus_client
        requests
      ]))
    ];

    script = "exec python3 ${exporter}/scrape.py $CREDENTIALS_DIRECTORY/config";
  };

  services.prometheus.scrapeConfigs = [ {
    job_name = "prometheus-packet-spot-price-exporter";
    metrics_path = "/metrics";
    static_configs = [ {
      targets = [
        "127.0.0.1:9400"
      ];
    } ] ;
  } ];
}
