{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "haumea-postgresql";
      metrics_path = "/metrics";
      static_configs = [ { targets = [ "haumea:9187" ]; } ];
    }
  ];
}
