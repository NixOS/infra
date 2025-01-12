{
  pkgs,
  ...
}:
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
    ruleFiles = [
      (pkgs.writeText "node-exporter.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "zfs";
              rules = [
                {
                  alert = "ZfsPoolFull";
                  expr = ''
                    (zfs_pool_free_bytes / zfs_pool_size_bytes) * 100 < 15
                  '';
                  for = "30m";
                  labels.severity = "warning";
                  annotations.summary = "ZFS pool {{ $labels.pool }} on {{ $labels.instance }} has only {{ $value }}% free space.";
                  annotations.grafana = "https://grafana.nixos.org/d/rYdddlPWk/node-exporter-full?orgId=1&var-job=node&var-node={{ $labels.instance }}";
                }
              ];
            }
          ];
        }
      ))
    ];
  };
}
