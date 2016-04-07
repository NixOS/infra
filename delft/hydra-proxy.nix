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
      ProxyPass         /.well-known !
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

  acmeKeyDir = "/var/lib/acme/hydra.nixos.org";
  acmeWebRoot = "/var/lib/httpd/acme";

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
        { urlPath = "/.well-known/acme-challenge";
          dir = "${acmeWebRoot}/.well-known/acme-challenge";
        }
      ];

    virtualHosts = [
      { hostName = "hydra.nixos.org";
        enableSSL = true;
        sslServerKey = "${acmeKeyDir}/key.pem";
        sslServerCert = "${acmeKeyDir}/fullchain.pem";
        extraConfig = ''
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

  # Let's Encrypt configuration.
  security.acme.certs."hydra.nixos.org" =
    { email = "edolstra@gmail.com";
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
        ${pkgs.openssl}/bin/openssl genrsa -passout pass:foo -des3 -out $dir/key-in.pem 1024
        ${pkgs.openssl}/bin/openssl req -passin pass:foo -new -key $dir/key-in.pem -out $dir/key.csr \
          -subj "/C=NL/ST=Denial/L=Springfield/O=Dis/CN=www.example.com"
        ${pkgs.openssl}/bin/openssl rsa -passin pass:foo -in $dir/key-in.pem -out $dir/key.pem
        ${pkgs.openssl}/bin/openssl x509 -req -days 365 -in $dir/key.csr -signkey $dir/key.pem -out $dir/fullchain.pem
      fi
    '';

}
