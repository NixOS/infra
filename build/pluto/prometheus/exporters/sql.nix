{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "sql";
      metrics_path = "/metrics";
      static_configs = [ { targets = [ "tracker.security.nixos.org:9237" ]; } ];
    }
  ];
}
