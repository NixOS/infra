{ config, lib, pkgs, ...}:

{
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
        error_page 403 /403.html;
        error_page 503 /503.html;
        location ~ ^/(403|503).html$ {
          root ${./nginx-error-pages};
          internal;
        }
      '';

      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
      };

      locations."/static/" = {
        alias = "${config.services.hydra-dev.package}/libexec/hydra/root/static/";
      };

      locations."/eval/1807542/restart-aborted".return = "403";
    };
  };

}
