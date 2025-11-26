{
  config,
  pkgs,
  ...
}:

{
  networking.firewall.allowedTCPPorts = [
    80
    443
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

  networking.firewall.extraInputRules = ''
    ip6 saddr $prometheus_inet6 tcp dport 9001 accept
    ip saddr $prometheus_inet4 tcp dport 9001 accept
  '';

  services.nginx = {
    enable = true;
    enableReload = true;

    recommendedBrotliSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    proxyTimeout = "900s";

    appendConfig = ''
      worker_processes auto;
    '';

    appendHttpConfig = ''
      map $request_uri $backend {
        default anubis;

        # downloads (e.g. distrobuilder for lxc/incus images)
        ~^/build/\d+/download/ hydra-server;
        ~^/build/\d+/download-by-type/ hydra-server;
        ~^/job/[^/]+/[^/]+/[^/]+/latest/download-by-type/file/ hydra-server;
      }

      limit_req_zone $binary_remote_addr zone=hydra-server:8m rate=2r/s;
      limit_req_status 429;
    '';

    eventsConfig = ''
      worker_connections 1024;
    '';

    upstreams = {
      anubis.servers."127.0.0.1:3001" = { };
      hydra-server.servers."127.0.0.1:3000" = { };
    };

    virtualHosts."hydra.nixos.org" = {
      forceSSL = true;
      enableACME = true;

      extraConfig = ''
        error_page 403 /403.html;
        error_page 502 /502.html;
        error_page 503 /503.html;
        location ~ /(403|502|503).html {
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

      locations."~ ^/job/[^/]+/[^/]+/metrics/metric/" = {
        proxyPass = "http://hydra-server";
      };

      locations."/" = {
        proxyPass = "http://$backend";
        extraConfig = ''
          limit_req zone=hydra-server burst=7;
        '';
      };

      locations."/static/" = {
        alias = "${config.services.hydra-dev.package}/libexec/hydra/root/static/";
      };
    };
  };
}
