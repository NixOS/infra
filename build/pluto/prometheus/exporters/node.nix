{ pkgs, ... }:

{
  services.prometheus = {
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            labels.role = "hydra";
            targets = [
              "mimas.nixos.org:9100"
            ];
          }
          {
            labels.role = "database";
            targets = [ "haumea:9100" ];
          }
          {
            labels.role = "monitoring";
            targets = [ "pluto:9100" ];
          }
          {
            labels.role = "services";
            targets = [
              "caliban.nixos.org:9100"
              "umbriel.nixos.org:9100"
              "tracker.security.nixos.org:9100"
            ];
          }
          {
            labels.role = "mac";
            targets = [
              # hetzner
              "intense-heron.mac.nixos.org:9100"
              "sweeping-filly.mac.nixos.org:9100"
              "maximum-snail.mac.nixos.org:9100"
              "growing-jennet.mac.nixos.org:9100"
              "enormous-catfish.mac.nixos.org:9100"
              # oakhost
              "kind-lumiere.mac.nixos.org:9100"
              "eager-heisenberg.mac.nixos.org:9100"
            ];
          }
        ];
      }
    ];

    ruleFiles =
      let
        diskSelector = ''mountpoint=~"(/|/scratch)",instance!~".*packethost.net"'';
        relevantLabels = "device,fstype,instance,mountpoint";
      in
      [
        (pkgs.writeText "node-exporter.rules" (
          builtins.toJSON {
            groups = [
              {
                name = "node";
                rules = [
                  {
                    alert = "PartitionLowInodes";
                    expr = ''
                      avg (node_filesystem_files_free{${diskSelector}} <= 10000) by (${relevantLabels})
                    '';
                    for = "30m";
                    labels.severity = "warning";
                    annotations.summary = "{{ $labels.device }} mounted to {{ $labels.mountpoint }} ({{ $labels.fstype }}) on {{ $labels.instance }} has {{ $value }} inodes free.";
                    annotations.grafana = "https://monitoring.nixos.org/grafana/d/5LANB9pZk/per-instance-metrics?orgId=1&refresh=30s&var-instance={{ $labels.instance }}";
                  }
                  {
                    alert = "PartitionLowDiskSpace";
                    expr = ''
                      (avg (round(node_filesystem_avail_bytes{${diskSelector}} * 10^(-9) <= 10)) by (${relevantLabels}))
                      or
                      (avg (((node_filesystem_avail_bytes{${diskSelector}} / node_filesystem_size_bytes) * 100) <= 10) by (${relevantLabels}))
                    '';
                    for = "30m";
                    labels.severity = "warning";
                    annotations.summary = "{{ $labels.device }} mounted to {{ $labels.mountpoint }} ({{ $labels.fstype }}) on {{ $labels.instance }} has {{ $value }} GB free.";
                    annotations.grafana = "https://monitoring.nixos.org/grafana/d/5LANB9pZk/per-instance-metrics?orgId=1&refresh=30s&var-instance={{ $labels.instance }}";
                  }
                  {
                    alert = "SystemdUnitFailed";
                    expr = ''node_systemd_unit_state{state="failed"} == 1'';
                    for = "15m";
                    labels.severity = "warning";
                    annotations.summary = "systemd unit {{ $labels.name }} on {{ $labels.instance }} has been down for more than 15 minutes.";
                  }
                ];
              }
              {
                name = "scheduled-jobs";
                rules = [
                  {
                    alert = "ChannelUpdateStuck";
                    expr = ''max_over_time(node_systemd_unit_state{name=~"^update-nix.*.service$",state=~"failed"}[5m]) == 1'';
                    for = "30m";
                    labels.severity = "warning";
                    annotations.summary = "{{ $labels.name }} on {{ $labels.instance }}";
                    annotations.grafana = "https://monitoring.nixos.org/grafana/d/fBW4tL1Wz/scheduled-task-state-channels-website?orgId=1&refresh=10s";
                  }
                ];
              }
            ];
          }
        ))
      ];
  };
}
