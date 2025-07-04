{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "postgresql";
      metrics_path = "/metrics";
      static_configs = [
        {
          targets = [
            "haumea:9187"
            "tracker.security.nixos.org:9187"
          ];
        }
      ];
    }
  ];
}
