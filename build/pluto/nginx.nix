{ config, ... }:

{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;

    eventsConfig = ''
      worker_connections 4096;
    '';

    virtualHosts."prometheus.nixos.org" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
      };
    };

    virtualHosts."grafana.nixos.org" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://unix:${config.services.grafana.settings.server.socket}";
        proxyWebsockets = true;
      };
    };
  };
}
