{ pkgs, ... }:

{
  services.prometheus = {
    scrapeConfigs = [
      {
        job_name = "rfc39";
        metrics_path = "/";
        static_configs = [
          {
            targets = [
              # intermittently available, when the rfc39-sync.service runs
              "127.0.0.1:9190"
            ];
          }
        ];
      }
    ];

    ruleFiles = [
      (pkgs.writeText "rfc39-exporter.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "rfc39";
              rules = [
                {
                  alert = "RFC39MaintainerSync";
                  expr = ''node_systemd_unit_state{name=~"^rfc39-sync.service$", state="failed"} == 1'';
                  for = "30m";
                  labels.severity = "warning";
                  annotations.grafana = "https://grafana.nixos.org/d/fBW4tL1Wz/scheduled-task-state-channels-website?orgId=1&refresh=10s";
                }
              ];
            }
          ];
        }
      ))
    ];
  };
}
