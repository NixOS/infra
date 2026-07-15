{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  genAgentRange =
    agent: from: to: sep: trailer:
    map (n: "${agent}${sep}${toString n}${trailer}") (lib.range from to);
in

{
  imports = [
    inputs.nixocaine.nixosModules.default
  ];

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.iocaine = {
    enable = true;
    config = {
      handler.default.config = {
        "ai-robots-txt-path" = inputs.ai-robots-txt;
        sources = {
          "training-corpus" = [
            (pkgs.fetchurl {
              name = "1984_djvu.txt";
              url = "https://archive.org/download/GeorgeOrwells1984/1984_djvu.txt";
              hash = "sha256-9R1PTa8yDtkfH+4rU5BF62ee73irhd3VYX1QB5KU+ZU=";
            })
            (pkgs.fetchurl {
              name = "brave-new-world.txt";
              url = "https://archive.org/download/ost-english-brave_new_world_aldous_huxley/Brave_New_World_Aldous_Huxley_djvu.txt";
              hash = "sha256-6WkaO/3zQIezGzJDp4QjglikiTZTxgo0P4MEff2mdcY=";
            })
          ];
          "wordlists" = [
            (pkgs.fetchurl {
              name = "words.txt";
              url = "https://git.savannah.gnu.org/cgit/miscfiles.git/plain/web2";
              hash = "sha256-KSmJWrP+x4xpY+vly7NJP+T8nhHroJWlInh7ivxTqGM=";
            })
          ];
        };
        unwanted-asns = {
          db-path = inputs.geolite2-asn-mmdb;
          list = map toString [
            7552 # VIETEL-AS-AP
            37963 # ALIBABA-CN-NET
            45102 # ALIBABA-CN-NET
            45899 # VNPT-AS-VN
            51167 # CONTABO
            62610 # ZEN-DPS
            132203 # TENCENT-NET-AP-CN
          ];
        };
        unwanted-visitors =
          # broad version ranges
          (genAgentRange "Android" 2 12 " " ".")
          ++ (genAgentRange "Chrome" 1 142 "/" ".")
          ++ (genAgentRange "CriOS" 1 142 "/" ".")
          ++ (genAgentRange "Firefox" 1 139 "/" ".")
          ++ (genAgentRange "Firefox" 141 150 "/" ".")
          ++ (genAgentRange "FxiOS" 1 150 "/" ".")
          ++ (genAgentRange "iPhone OS" 1 14 " " "_")
          ++ (genAgentRange "Windows NT" 4 7 " " "")
          ++ (genAgentRange "Mac OS X" 11 14 " " "")
          ++ [
            # manually crafted patterns
            "Mac OS X 10." # should be 10_
            "Mac OS X 10_5"
            "Mac OS X 10_6"
            "Mac OS X 10_7"
            "Mac OS X 10_8"
            "Mac OS X 10_9"
            "Mac OS X 10_10"
            "Mac OS X 10_11"
            "Mac OS X 10_12"
            "Mac OS X 10_13"
            "Mac OS X 10_14"
            "iPod;"
            "Presto/"
            "Trident/"
            "Windows CE"
            # Missing contact information
            "efx-scanner/3.0"
            "Go-http-client/1.1"
          ];
      };
      server.default = {
        bind = "/run/iocaine/default.sock";
        unix-socket-access = "group";
        mode = "http";
        use = {
          handler-from = "default";
          metrics = "metrics";
        };
      };
      server.metrics = {
        bind = "[::]:42042";
        mode = "prometheus";
      };
    };
  };

  networking.firewall.extraInputRules = ''
    ip6 saddr $prometheus_inet6 tcp dport { 9001, 42042 } accept
    ip saddr $prometheus_inet4 tcp dport { 9001, 42042 } accept
  '';

  # Kill the hard dependency on iocaine
  systemd.services.nginx = {
    requires = lib.mkForce [ ];
    after = lib.mkForce [ "network.target" ];
  };

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
      limit_req_zone $binary_remote_addr zone=hydra-server:8m rate=2r/s;
      limit_req_status 429;
    '';

    eventsConfig = ''
      worker_connections 1024;
    '';

    upstreams = {
      iocaine.servers."unix:${config.services.iocaine.config.server.default.bind}" = { };
      hydra-server.servers."127.0.0.1:3000" = { };
    };

    virtualHosts."mimas.nixos.org" = {
      forceSSL = true;
      enableACME = true;
      default = true;
      locations."/".return = "444";
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

      locations."/" = {
        proxyPass = "http://iocaine";
        extraConfig = ''
          # allow nginx to intercept non-200 responses
          proxy_intercept_errors on;

          # optionally retry upstream on certain failures
          proxy_next_upstream error timeout;

          # treat 421 as a special fallback condition
          # treat 502 when iocaine is down
          error_page 421 502 = @hydra;

          # discard the noise
          access_log off;

          # don't spend time compressing garbage
          gzip off;
        '';
      };

      locations."~ ^/job/[^/]+/[^/]+/metrics/metric/" = {
        proxyPass = "http://hydra-server";
      };

      locations."@hydra" = {
        proxyPass = "http://hydra-server";
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
