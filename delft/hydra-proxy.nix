{ config, lib, pkgs, ...}:

let

  hydraCacheDir = "/var/cache/hydra-binary-cache";

  hydraProxyConfig =
    ''
      TimeOut 900

      <Proxy *>
        Order deny,allow
        Allow from all
      </Proxy>

      ProxyRequests     Off
      ProxyPreserveHost On
      ProxyPass         /apache-errors !
      ErrorDocument 503 /apache-errors/503.html
      ProxyPass         /       http://localhost:3000/ retry=5 disablereuse=on
      ProxyPassReverse  /       http://localhost:3000/

      CacheEnable disk /
      CacheRoot ${hydraCacheDir}
      CacheMaxFileSize 64000000
      CacheIgnoreHeaders Set-Cookie

      <Location />
        SetOutputFilter DEFLATE
        BrowserMatch ^Mozilla/4\.0[678] no-gzip\
        BrowserMatch \bMSI[E] !no-gzip !gzip-only-text/html
        SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png|narinfo)$ no-gzip dont-vary
        SetEnvIfNoCase Request_URI /api/ no-gzip dont-vary
        SetEnvIfNoCase Request_URI /download/ no-gzip dont-vary
        SetEnvIfNoCase Request_URI /nar/ no-gzip dont-vary
      </Location>
    '';

in

{

  services.httpd = {
    enable = true;
    adminAddr = "edolstra@gmail.com";
    hostName = "hydra.nixos.org";
    logFormat = ''"%h %l %u %t \"%r\" %>s %b %D"'';
    extraConfig = hydraProxyConfig;

    servedDirs =
      [ { urlPath = "/apache-errors";
          dir = ./apache-errors;
        }
      ];

    virtualHosts = [
      { hostName = "hydra.nixos.org";
        enableSSL = true;
        sslServerCert = "/root/ssl-secrets/ssl-nixos.org.crt";
        sslServerKey = "/root/ssl-secrets/ssl-nixos.org.key";
        extraConfig = ''
          SSLCertificateChainFile /root/ssl-secrets/startssl-class1.pem
          SSLCACertificateFile /root/ssl-secrets/startssl-ca.pem

          # Required by Catalyst.
          RequestHeader set X-Forwarded-Proto https
          RequestHeader set X-Forwarded-Port 443
        '';
      }
    ];

  };

  system.activationScripts.createHydraCache =
    ''
      mkdir -p ${hydraCacheDir}
      chown wwwrun ${hydraCacheDir}
    '';

  systemd.services.htcacheclean =
    { description = "Clean httpd Cache";
      serviceConfig.ExecStart =
        "${config.services.httpd.package}/bin/htcacheclean " +
        "-v -t -l 32G -p /var/cache/hydra-binary-cache";
      startAt = "Sat 05:45";
    };

}
