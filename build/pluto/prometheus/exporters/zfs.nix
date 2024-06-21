{
  services.prometheus = {
    scrapeConfigs = [ {
      job_name = "zfs";
      static_configs = [ {
        targets = [
          "rhea:9134"
          "haumea:9134"
          "pluto:9134"
        ];
      } ];
    } ];
  };
}
