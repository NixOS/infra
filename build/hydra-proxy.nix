{
  config,
  pkgs,
  ...
}:

{
  networking.firewall.allowedTCPPorts = [
    80
    443
    9001
  ];

  services.anubis.instances."hydra-server" = {
    settings = {
      TARGET = "http://127.0.0.1:3000";
      BIND = ":3001";
      BIND_NETWORK = "tcp";
      METRICS_BIND = ":9001";
      METRICS_BIND_NETWORK = "tcp";
    };
  };

  services.nginx = {
    enable = true;
    enableReload = true;

    recommendedBrotliSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedZstdSettings = true;

    proxyTimeout = "900s";

    appendConfig = ''
      worker_processes auto;
    '';

    eventsConfig = ''
      worker_connections 1024;
    '';

    virtualHosts."hydra.nixos.org" = {
      forceSSL = true;
      enableACME = true;

      extraConfig = ''
        error_page 502 /502.html;
        error_page 503 /503.html;
        location ~ /(502|503).html {
          root ${./nginx-error-pages};
          internal;
        }
      '';

      # Ask robots not to scrape hydra, it has various expensive endpoints
      locations."=/robots.txt".alias = pkgs.writeText "hydra.nixos.org-robots.txt" ''
        User-agent: *
        Disallow: /
        Allow: /$
      '';

      locations."/" = {
        proxyPass = "http://127.0.0.1:3001";
      };

      locations."/static/" = {
        alias = "${config.services.hydra-dev.package}/libexec/hydra/root/static/";
      };
    };
  };
}
