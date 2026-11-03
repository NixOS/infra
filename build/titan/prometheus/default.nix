{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./alertmanager.nix
    ./exporters/blackbox.nix
    ./exporters/channel.nix
    ./exporters/dmarc.nix
    ./exporters/domain.nix
    ./exporters/elasticsearch.nix
    ./exporters/fastly.nix
    ./exporters/github.nix
    ./exporters/hydra.nix
    ./exporters/iocaine.nix
    ./exporters/json.nix
    ./exporters/matrix-synapse.nix
    ./exporters/nixos.nix
    ./exporters/nixpkgs-update.nix
    ./exporters/node.nix
    ./exporters/owncast.nix
    ./exporters/postgresql.nix
    ./exporters/rasdaemon.nix
    ./exporters/storagebox.nix
    ./exporters/sql.nix
    ./exporters/up.nix
    ./exporters/zfs.nix
    ./exporters/zrepl.nix
  ];

  services.backup.includesZfsDatasets = [ "/var/lib/prometheus2" ];

  services.nginx.virtualHosts."prometheus.nixos.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
    };
  };

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
