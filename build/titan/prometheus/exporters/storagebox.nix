{
  config,
  pkgs,
  ...
}:
{
  age.secrets."storagebox-exporter-token".file = ../../../secrets/storagebox-exporter-token.age;

  services.prometheus = {
    exporters.storagebox = {
      enable = true;
      listenAddress = "localhost";
      tokenFile = config.age.secrets."storagebox-exporter-token".path;
    };

    scrapeConfigs = [
      {
        job_name = "storagebox";
        scheme = "http";
        static_configs = [ { targets = [ "localhost:9509" ]; } ];
      }
    ];

    ruleFiles = [
      (pkgs.writeText "storagebox-exporter.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "storagebox";
              rules = [
                {
                  alert = "StorageboxCapacity";
                  expr = "round(100 * (1 - (storagebox_disk_usage / storagebox_disk_quota))) < 10";
                  for = "30m";
                  labels.severity = "warning";
                  annotations.summary = "StorageBox {{ $labels.name }} ({ $labels.server }}) has less than {{ $value }}% free space.";
                }
              ];
            }
          ];
        }
      ))
    ];
  };
}
