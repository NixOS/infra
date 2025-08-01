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
              "makemake.ngi.nixos.org:9100"
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
              # macstadium
              "mac01.ofborg.org:9100"
              "mac02.ofborg.org:9100"
              "mac03.ofborg.org:9100"
              "mac04.ofborg.org:9100"
              "mac05.ofborg.org:9100"
            ];
          }
          {
            labels.role = "builders";
            targets = [
              "elated-minsky.builder.nixos.org:9100"
              "sleepy-brown.builder.nixos.org:9100"
              "goofy-hopcroft.builder.nixos.org:9100"
              "hopeful-rivest.builder.nixos.org:9100"
            ];
          }
          {
            labels.role = "ofborg";
            targets = [
              "build01.ofborg.org:9100"
              "build02.ofborg.org:9100"
              "build03.ofborg.org:9100"
              "build04.ofborg.org:9100"
              "build05.ofborg.org:9100"
              "core01.ofborg.org:9100"
              "eval01.ofborg.org:9100"
              "eval02.ofborg.org:9100"
              "eval03.ofborg.org:9100"
              "eval04.ofborg.org:9100"
            ];
          }
        ];
      }
    ];

    ruleFiles =
      let
        diskSelector = ''mountpoint="/"'';
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
                      node_filesystem_files_free{${diskSelector}} / node_filesystem_files{${diskSelector}} * 100 < 10
                    '';
                    for = "30m";
                    labels.severity = "warning";
                    annotations.summary = "{{ $labels.device }} mounted to {{ $labels.mountpoint }} ({{ $labels.fstype }}) on {{ $labels.instance }} has only {{ $value }}% free inodes.";
                    annotations.grafana = "https://grafana.nixos.org/d/rYdddlPWk/node-exporter-full?orgId=1&var-job=node&var-node={{ $labels.instance }}";
                  }
                  {
                    alert = "PartitionLowDiskSpace";
                    expr = ''
                      round((node_filesystem_free_bytes{${diskSelector}} * 100) / node_filesystem_size_bytes{${diskSelector}}) < 10 and ON (instance, device, mountpoint) node_filesystem_free_bytes < 100 * 1024^3
                    '';
                    for = "30m";
                    labels.severity = "warning";
                    annotations.summary = "{{ $labels.device }} mounted to {{ $labels.mountpoint }} ({{ $labels.fstype }}) on {{ $labels.instance }} has {{ $value }}% free.";
                    annotations.grafana = "https://grafana.nixos.org/d/rYdddlPWk/node-exporter-full?orgId=1&var-job=node&var-node={{ $labels.instance }}";
                  }
                  {
                    alert = "SystemdUnitFailed";
                    expr = ''
                      node_systemd_unit_state{state="failed"} == 1
                    '';
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
