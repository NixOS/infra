{ ... }:

{
  services.prometheus = {
    scrapeConfigs = [
      {
        job_name = "zrepl";
        static_configs = [
          {
            labels.role = "database";
            targets = [
              "titan.nixos.org:9811"
            ];
          }
        ];
      }
    ];

    # TODO: alert on `zrepl_replication_last_successful` being too long ago.
  };
}
