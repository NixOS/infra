{ ... }:

{
  imports = [
    ./alertmanager.nix
    ./exporters/up.nix
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
    ./exporters/r13y.nix
    ./exporters/rfc39.nix
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
      "--storage.tsdb.retention=${toString (720 * 24)}h"
      "--web.external-url=https://prometheus.nixos.org/"
    ];
    globalConfig.scrape_interval = "15s";
  };
}
