{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "nixos";
      static_configs = [
        {
          labels.role = "hydra";
          targets = [
            "mimas.nixos.org:9300"
          ];
        }
        {
          labels.role = "monitoring";
          targets = [
            "pluto.nixos.org:9300"
          ];
        }
        {
          labels.role = "database";
          targets = [
            "haumea.nixos.org:9300"
          ];
        }
      ];
    }
  ];
}
