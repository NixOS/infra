{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "matrix_synapse";
      scheme = "https";

      static_configs = [
        {
          targets = [ "matrix.nixos.org:443" ];
          labels = {
            index = "main";
            __metrics_path__ = "/metrics/main";
          };
        }
        {
          targets = [ "matrix.nixos.org:443" ];
          labels = {
            index = "client1";
            __metrics_path__ = "/metrics/client1";
          };
        }
        {
          targets = [ "matrix.nixos.org:443" ];
          labels = {
            index = "client2";
            __metrics_path__ = "/metrics/client2";
          };
        }
      ];
    }
  ];
}
