{ config, ... }:

{
  age.secrets.fastly-exporter-env.file = ../../../secrets/fastly-exporter-env.age;

  services.prometheus = {
    exporters.fastly = {
      enable = true;
      listenAddress = "127.0.0.1";
      environmentFile = config.age.secrets.fastly-exporter-env.path;
    };

    scrapeConfigs = [
      {
        job_name = "fastly";
        metrics_path = "/metrics";
        static_configs = [ { targets = [ "127.0.0.1:9118" ]; } ];
      }
    ];
  };
}
