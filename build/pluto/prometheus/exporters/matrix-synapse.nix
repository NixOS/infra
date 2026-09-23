{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "matrix_synapse";
      scheme = "https";

      static_configs =
        map
          (index: {
            targets = [ "matrix.nixos.org:443" ];
            labels = {
              inherit index;
              __metrics_path__ = "/metrics/${index}";
            };
          })
          [
            "main"
            "client1"
            "client2"
            "client3"
            "client4"
            "federation_sender1"
            "federation_sender2"
            "federation_sender3"
            "federation_sender4"
          ];
    }
  ];
}
