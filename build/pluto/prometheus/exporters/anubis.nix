{
  services.prometheus = {
    scrapeConfigs = [
      {
        job_name = "anubis";
        static_configs = [
          {
            targets = [
              "hydra.nixos.org:9001"
            ];
          }
        ];
      }
    ];
  };
}
