{ config, lib, pkgs, ...}:

let

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
      ProxyPass         /.well-known !
      ErrorDocument 503 /apache-errors/503.html
      ProxyPass         /       http://127.0.0.1:3000/ retry=5 disablereuse=on
      ProxyPassReverse  /       http://127.0.0.1:3000/

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
    logFormat = ''"%h %l %u %t \"%r\" %>s %b %D"'';
    extraConfig = hydraProxyConfig +
      ''
        RewriteEngine On
        RewriteCond %{HTTPS} off
        RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
      '';

    virtualHosts."hydra.nixos.org" =
      { forceSSL = true;
        enableACME = true;
        extraConfig = ''
          # Required by Catalyst.
          RequestHeader set X-Forwarded-Proto https
          RequestHeader set X-Forwarded-Port 443
          Header always set Strict-Transport-Security "max-age=15552000"

          RewriteEngine On
          RewriteCond %{QUERY_STRING} ^query=pkgs.chromium$
          RewriteRule ^/search$ - [L,R=429,NC]
        '';
        listenAddresses = [ "[::]" ];
        servedDirs =
          [ { urlPath = "/apache-errors";
              dir = ./apache-errors;
            }
          ];
      };

  };

}
