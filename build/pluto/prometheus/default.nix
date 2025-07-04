{ pkgs, ... }:

{
  imports = [
    ./alertmanager.nix
    ./exporters/anubis.nix
    ./exporters/blackbox.nix
    ./exporters/channel.nix
    ./exporters/domain.nix
    ./exporters/fastly.nix
    ./exporters/github.nix
    ./exporters/hydra.nix
    ./exporters/json.nix
    ./exporters/matrix-synapse.nix
    ./exporters/nixos.nix
    ./exporters/node.nix
    ./exporters/owncast.nix
    ./exporters/postgresql.nix
    ./exporters/rasdaemon.nix
    ./exporters/sql.nix
    ./exporters/up.nix
    ./exporters/zfs.nix
  ];

  networking.extraHosts = ''
    10.254.1.6 pluto

    10.254.1.9 haumea

    10.254.3.1 webserver
  '';

  networking.firewall.allowedTCPPorts = [ 9090 ];

  services.backup.includesZfsDatasets = [ "/var/lib/prometheus2" ];

  services.prometheus = {
    enable = true;
    extraFlags = [
      "--storage.tsdb.retention.time=${toString (720 * 24)}h"
      "--web.external-url=https://prometheus.nixos.org/"
    ];
    globalConfig.scrape_interval = "15s";

    ruleFiles = [
      (pkgs.writeText "up.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "up";
              rules = [
                {
                  alert = "NotUp";
                  expr = ''
                    up == 0
                  '';
                  for = "10m";
                  labels.severity = "warning";
                  annotations.summary = "scrape job {{ $labels.job }} is failing on {{ $labels.instance }}";
                }
              ];
            }
          ];
        }
      ))
    ];
  };
}
