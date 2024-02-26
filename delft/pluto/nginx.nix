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
      locations."~ ^/prometheus/(?<action>[^\\s]+)" = {
        return = "301 https://prometheus.nixos.org/$action$is_args$args";
        # TODO: Remove after https://github.com/NixOS/nixos-status/pull/21
        extraConfig = ''
          add_header Access-Control-Allow-Origin "*" always;
        '';
      };
      locations."~ ^/grafana/(?<action>[^\\s]+)".return = "301 https://grafana.nixos.org/$action$is_args$args";
    };

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
      locations."/".proxyPass = "http://${config.services.grafana.addr}:${toString config.services.grafana.port}";
    };
  };
}
