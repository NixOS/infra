{ pkgs
, ...
}:

{
  networking.firewall.allowedTCPPorts = [ 9200 ];

  systemd.services.prometheus-hydra-queue-runner-exporter = {
    wantedBy = [
      "multi-user.target"
    ];
    after = [
      "network.target"
    ];
    wants = [
      "network.target"
    ];
    serviceConfig = {
      DynamicUser = true;
      Restart = "always";
      RestartSec = "60s";
      PrivateTmp = true;
      WorkingDirectory = "/tmp";
      ExecStart = let
        python = pkgs.python3.withPackages (ps: with ps; [
          requests
          prometheus_client
        ]);
      in
      ''
        ${python.interpreter} ${./hydra-queue-runner-reexporter.py}
      '';
    };
  };

  services.prometheus = {
    scrapeConfigs = [ {
      job_name = "hydra";
      metrics_path = "/prometheus";
      scheme = "https";
      static_configs = [ {
        targets = [
          "hydra.nixos.org:443"
        ];
      } ];
    } {
      job_name = "hydra_notify";
      metrics_path = "/metrics";
      scheme = "http";
      static_configs = [ {
        targets = [
          "hydra.nixos.org:9199"
        ];
      } ];
    } {
      job_name = "hydra_queue_runner";
      metrics_path = "/metrics";
      scheme = "http";
      static_configs = [ {
        targets = [
          "hydra.nixos.org:9198"
        ];
      } ];
    } {
      job_name = "hydra-webserver";
      metrics_path = "/metrics";
      scheme = "https";
      static_configs = [ {
        targets = [
          "hydra.nixos.org:443"
        ];
      } ];
    } {
      job_name = "hydra-reexport";
      metrics_path = "/";
      static_configs = [ {
        targets = [
          "monitoring.nixos.org:9200"
        ];
      } ];
    } ];

    ruleFiles = [
      (pkgs.writeText "hydra-exporter.rules" (builtins.toJSON {
        groups = [ {
          name = "hydra";
          rules = [ {
            alert = "BuildsStuckOverTwoDays";
            expr = ''hydra_machine_build_duration_bucket{le="+Inf"} - ignoring(le) hydra_machine_build_duration_bucket{le="172800"} > 0'';
            for = "30m";
            labels.severity = "warning";
            annotations.summary = "{{ $labels.machine }} has {{ $value }} over-age jobs.";
            annotations.grafana = "https://monitoring.nixos.org/grafana/d/j0hJAY1Wk/in-progress-build-duration-heatmap";
          } {
            alert = "HydraQueueRunnerUp";
            expr = ''up{job="hydra_queue_runner"} == 0'';
            for = "30m";
            labels.severity = "warning";
            annotations.summary = "hydra-queue-runner's prometheus exporter is not up";
          } ];
        } ];
      }))
    ];
  };
}
