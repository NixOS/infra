{
  services.prometheus.scrapeConfigs = [ {
    job_name = "matrix_synapse";
    scheme = "https";
    static_configs = [ {
      targets = [
        "matrix.nixos.org:443"
      ];
    } ];
  } ];
}
