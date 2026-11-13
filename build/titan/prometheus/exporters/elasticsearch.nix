{ config, ... }:

{
  # Note that the credentials are technically in the nixos-search repo in plaintext,
  # so mostly using age here for good form.
  age.secrets.elasticsearch-exporter-env.file = ../../../secrets/elasticsearch-exporter-env.age;

  services.prometheus = {
    exporters.elasticsearch = {
      enable = true;
      listenAddress = "127.0.0.1";
      url = "https://nixos-search-7-1733963800.us-east-1.bonsaisearch.net";
      environmentFile = config.age.secrets.elasticsearch-exporter-env.path;
      extraFlags = [
        "--es.all"
        "--es.indices"
        "--collector.clustersettings"
        "--collector.snapshots"
      ];
    };

    scrapeConfigs = [
      {
        job_name = "prometheus-elasticsearch-exporter";
        static_configs = [ { targets = [ "127.0.0.1:9114" ]; } ];
      }
    ];
  };
}
