{
  services.prometheus.scrapeConfigs = [ {
    job_name = "r13y";
    scheme = "https";
    metrics_path = "/metrics";
    static_configs = [ {
      targets = [
        "r13y.com"
      ];
    } ];
  } ];
}
