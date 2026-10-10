{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "nar-serve";
      static_configs = [ { targets = [ "caliban.nixos.org:9464" ]; } ];
    }
  ];
}
