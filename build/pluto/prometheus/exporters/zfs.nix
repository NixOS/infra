{
  services.prometheus = {
    scrapeConfigs = [
      {
        job_name = "zfs";
        static_configs = [
          {
            targets = [
              "haumea:9134"
              "pluto:9134"
              "mimas.nixos.org:9134"
            ];
          }
        ];
      }
    ];
  };
}
