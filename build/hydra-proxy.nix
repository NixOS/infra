{
  config,
  lib,
  pkgs,
  ...
}:

let
  bannedUserAgentPatterns = [
    "Trident/"
    "Android\\s[123456789]\\."
    "iPod"
    "iPad\\sOS\\s"
    "iPhone\\sOS\\s[23456789]"
    "Opera/[89]"
    "(Chrome|CriOS)/(\\d\\d?\\.|1[01]|12[4])"
    "(Firefox|FxiOS)/(\\d\\d?\\.|1[01]|12[012345679]\\.)"
    "PPC\\sMac\\sOS"
    "Windows\\sCE"
    "Windows\\s95"
    "Windows\\s98"
    "Windows\\sNT\\s[12345]\\."
  ];
in
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

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

    appendHttpConfig = ''
      map $http_user_agent $badagent {
        default 0;
        ${lib.concatMapStringsSep "\n" (pattern: ''
          ~${pattern} 1;
        '') bannedUserAgentPatterns}
      }
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
        proxyPass = "http://127.0.0.1:3000";
        extraConfig = ''
          if ($badagent) {
            access_log /var/log/nginx/abuse.log;
            return 403;
          }
        '';
      };

      locations."/static/" = {
        alias = "${config.services.hydra-dev.package}/libexec/hydra/root/static/";
      };
    };
  };

}
