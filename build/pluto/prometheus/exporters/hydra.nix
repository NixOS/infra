{ pkgs, ... }:

{
  services.prometheus = {
    scrapeConfigs = [
      {
        job_name = "hydra";
        metrics_path = "/prometheus";
        scheme = "https";
        static_configs = [ { targets = [ "hydra.nixos.org:443" ]; } ];
      }
      {
        job_name = "hydra_queue_runner";
        metrics_path = "/metrics";
        scheme = "https";
        static_configs = [ { targets = [ "queue-runner.hydra.nixos.org:443" ]; } ];
      }
      {
        job_name = "hydra-webserver";
        metrics_path = "/metrics";
        scheme = "https";
        static_configs = [ { targets = [ "hydra.nixos.org:443" ]; } ];
      }
    ];

    ruleFiles = [
      (pkgs.writeText "hydra-exporter.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "hydra";
              rules = [
                {
                  alert = "BuildsStuckOverTwoDays";
                  expr = ''hydra_machine_build_duration_bucket{le="+Inf"} - ignoring(le) hydra_machine_build_duration_bucket{le="172800"} > 0'';
                  for = "30m";
                  labels.severity = "warning";
                  annotations.summary = "{{ $labels.machine }} has {{ $value }} over-age jobs.";
                  annotations.grafana = "https://grafana.nixos.org/d/j0hJAY1Wk/in-progress-build-duration-heatmap";
                }
              ];
            }
          ];
        }
      ))
    ];
  };
}
