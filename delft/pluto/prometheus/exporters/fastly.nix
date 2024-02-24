{ config
, lib
, pkgs
, ...
}:

{
  age.secrets.fastly-read-only-api-token.file = ../../../secrets/fastly-read-only-api-token.age;

  systemd.services.prometheus-fastly-exporter = {
    # module script is outdated; https://github.com/NixOS/nixpkgs/pull/287348
    script = with config.services.prometheus.exporters.fastly; lib.mkForce ''
      export FASTLY_API_TOKEN=$(cat ${tokenPath})
      ${pkgs.prometheus-fastly-exporter}/bin/fastly-exporter \
        -listen ${listenAddress}:${toString port}
    '';
    serviceConfig.LoadCredential = "fastyl-api-token:${config.age.secrets.fastly-read-only-api-token.path}";
  };

  services.prometheus = {
    exporters.fastly = {
      enable = true;
      listenAddress = "127.0.0.1";
      tokenPath = "/run/credentials/prometheus-fastly-exporter.service/fastyl-api-token";
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
