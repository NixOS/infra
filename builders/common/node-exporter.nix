{
  config,
  ...
}:

{
  networking.firewall.allowedTCPPorts = [
    config.services.prometheus.exporters.node.port
  ];

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
  };
}
