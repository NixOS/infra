{ config
, ...
}:

{
  age.secrets.fastly-read-only-api-token.file = ../../../secrets/fastly-read-only-api-token.age;

  services.prometheus = {
    exporters.fastly = {
      enable = true;
      listenAddress = "127.0.0.1";
      tokenPath = config.age.secrets.fastly-read-only-api-token.path;
    };

    scrapeConfigs = [ {
      job_name = "fastly";
      metrics_path = "/metrics";
      static_configs = [ {
        targets = [
          "127.0.0.1:9118"
        ];
      } ];
    } ];
  };
}
