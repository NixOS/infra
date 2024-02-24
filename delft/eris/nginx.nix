{ config
, ...
}:

{
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;

    eventsConfig = ''
      worker_connections 4096;
    '';

    virtualHosts."monitoring.nixos.org" = {
      enableACME = true;
      forceSSL = true;
      default = true;
      locations."/".return = "302 https://status.nixos.org";
      locations."/prometheus/".proxyPass = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
      locations."/grafana/".proxyPass = "http://${config.services.grafana.addr}:${toString config.services.grafana.port}/";
    };
  };
}
