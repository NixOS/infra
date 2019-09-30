{ pkgs, ... }:
{
  networking.firewall.allowedTCPPorts = [ 9100 ];
  services.prometheus.exporters.node = {
    enable = true;

    extraFlags = [
      "--collector.textfile.directory=/var/lib/prometheus-node-exporter-text-files"
    ];
  };

  system.activationScripts.node-exporter-system-version = ''
    mkdir -pm 0775 /var/lib/prometheus-node-exporter-text-files

    cd /var/lib/prometheus-node-exporter-text-files
    ${./system-version-exporter.sh} | ${pkgs.moreutils}/bin/sponge system-version.prom
  '';
}
