{
  config,
  ...
}:

{
  hardware.rasdaemon = {
    enable = true;
    record = true;
  };

  services.prometheus.exporters.rasdaemon = {
    enable = true;
    enabledCollectors = [
      "aer"
      "mce"
      "mc"
      "extlog"
      "devlink"
      "disk"
    ];
    openFirewall = true;
    firewallRules = ''
      ip6 saddr $prometheus_inet6 tcp dport ${toString config.services.prometheus.exporters.rasdaemon.port} accept
      ip saddr $prometheus_inet4 tcp dport ${toString config.services.prometheus.exporters.rasdaemon.port} accept
    '';
  };
}
