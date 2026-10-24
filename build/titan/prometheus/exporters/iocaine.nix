{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "iocaine";
      static_configs = [ { targets = [ "mimas.nixos.org:42042" ]; } ];
    }
  ];
}
