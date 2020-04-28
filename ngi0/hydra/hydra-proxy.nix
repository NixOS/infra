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

  acmeKeyDir = "/var/lib/acme/hydra.ngi0.nixos.org";
  acmeWebRoot = "/var/lib/httpd/acme";

in

{

  services.httpd = {
    enable = true;
    adminAddr = "ngi@nixos.org";
    logFormat = ''"%h %l %u %t \"%r\" %>s %b %D"'';
    extraConfig = hydraProxyConfig +
      ''
        RewriteEngine On
        RewriteCond %{HTTPS} off
        RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
      '';

    virtualHosts."hydra.ngi0.nixos.org" =
      { addSSL = true;
        sslServerKey = "${acmeKeyDir}/key.pem";
        sslServerCert = "${acmeKeyDir}/fullchain.pem";
        extraConfig = ''
          # Required by Catalyst.
          RequestHeader set X-Forwarded-Proto https
          RequestHeader set X-Forwarded-Port 443
          Header always set Strict-Transport-Security "max-age=15552000"
        '';
        servedDirs =
          [ { urlPath = "/apache-errors";
              dir = ../../delft/apache-errors;
            }
            { urlPath = "/.well-known/acme-challenge";
              dir = "${acmeWebRoot}/.well-known/acme-challenge";
            }
          ];
      };

  };

  # Let's Encrypt configuration.
  security.acme.acceptTerms = true;
  security.acme.certs."hydra.ngi0.nixos.org" =
    { email = "ngi@nixos.org";
      webroot = acmeWebRoot;
      postRun = "systemctl reload httpd.service";
    };

  # Generate a dummy self-signed certificate until we get one from
  # Let's Encrypt.
  system.activationScripts.createDummyKey =
    ''
      dir=${acmeKeyDir}
      mkdir -m 0700 -p $dir
      if ! [[ -e $dir/key.pem ]]; then
        ${pkgs.openssl}/bin/openssl genrsa -passout pass:foobar -des3 -out $dir/key-in.pem 1024
        ${pkgs.openssl}/bin/openssl req -passin pass:foobar -new -key $dir/key-in.pem -out $dir/key.csr \
          -subj "/C=NL/ST=Denial/L=Springfield/O=Dis/CN=www.example.com"
        ${pkgs.openssl}/bin/openssl rsa -passin pass:foobar -in $dir/key-in.pem -out $dir/key.pem
        ${pkgs.openssl}/bin/openssl x509 -req -days 365 -in $dir/key.csr -signkey $dir/key.pem -out $dir/fullchain.pem
      fi
    '';

}
