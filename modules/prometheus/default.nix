{ pkgs, ... }:

let
  prometheus-nixos-exporter = pkgs.callPackage ./nixos-exporter { };
in
{
  networking.firewall.allowedTCPPorts = [
    9100 # node-exporter
    9300 # prometheus-nixos-exporter
  ];
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
    extraFlags = [ "--collector.textfile.directory=/var/lib/prometheus-node-exporter-text-files" ];
  };

  system.activationScripts.node-exporter-system-version = ''
    mkdir -pm 0775 /var/lib/prometheus-node-exporter-text-files

    cd /var/lib/prometheus-node-exporter-text-files
    ${./system-version-exporter.sh} | ${pkgs.moreutils}/bin/sponge system-version.prom
  '';

  systemd.services.prometheus-nixos-exporter = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    path = [
      pkgs.nix
      pkgs.bash
    ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "60s";
      ExecStart = "${prometheus-nixos-exporter}/bin/prometheus-nixos-exporter";
    };
  };

  services.prometheus.exporters.zfs = {
    enable = true;
    listenAddress = "[::]";
    openFirewall = true;
  };
}
