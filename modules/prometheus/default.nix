{
  config,
  pkgs,
  ...
}:

let
  prometheus-nixos-exporter = pkgs.callPackage ./nixos-exporter { };
in
{
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
    extraFlags = [ "--collector.textfile.directory=/var/lib/prometheus-node-exporter-text-files" ];
    openFirewall = true;
    firewallRules = ''
      ip6 saddr $prometheus_inet6 tcp dport ${toString config.services.prometheus.exporters.node.port} accept
      ip saddr $prometheus_inet4 tcp dport ${toString config.services.prometheus.exporters.node.port} accept
    '';
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

  networking.firewall.extraInputRules = ''
    # prometheus-nixos-exporter
    ip6 saddr $prometheus_inet6 tcp dport 9300 accept
    ip saddr $prometheus_inet4 tcp dport 9300 accept
  '';

  services.prometheus.exporters.zfs = {
    enable = true;
    listenAddress = "[::]";
    openFirewall = true;
    firewallRules = ''
      ip6 saddr $prometheus_inet6 tcp dport ${toString config.services.prometheus.exporters.zfs.port} accept
      ip saddr $prometheus_inet4 tcp dport ${toString config.services.prometheus.exporters.zfs.port} accept
    '';
  };
}
