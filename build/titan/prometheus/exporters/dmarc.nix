{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "dmarc";
      static_configs = [ { targets = [ "umbriel.nixos.org:9797" ]; } ];
    }
  ];
}
