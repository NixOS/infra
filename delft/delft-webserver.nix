{ config, pkgs, ... }:

with pkgs.lib;

let

  zabbixMail = pkgs.writeScriptBin "zabbix-mail" ''
    #!/bin/sh
    set -e

    export zabbixemailto="$1"
    export zabbixsubject="$2"
    export zabbixbody="$3"

    ${pkgs.ssmtp}/sbin/sendmail -v $zabbixemailto <<EOF
    Subject: $zabbixsubject
    To: $zabbixemailto
    
    $zabbixbody
    EOF
  '';

  ZabbixApacheUpdater = pkgs.fetchsvn {
    url = https://www.zulukilo.com/svn/pub/zabbix-apache-stats/trunk/fetch.py;
    sha256 = "1q66x429wpqjqcmlsi3x37rkn95i55nj8ldzcrblnx6a0jnjgd2g";
    rev = 94;
  };

  strategoxtVHostConfig =
    { hostName = "strategoxt.org";
      servedFiles = [
        { urlPath = "/freenode.ver";
          file = "/data/pt-wiki/pub/freenode.ver";
        }
      ];
      extraSubservices = [
        { function = import /etc/nixos/services/twiki;
          startWeb = "Stratego/WebHome";
          dataDir = "/data/pt-wiki/data";
          pubDir = "/data/pt-wiki/pub";
          twikiName = "Stratego/XT Wiki";
          registrationDomain = "ewi.tudelft.nl";
        }
      ];
    };

  strategoxtSSLConfig =
    { enableSSL = true;
      sslServerCert = "/root/ssl-secrets/ssl-strategoxt-org.crt";
      sslServerKey = "/root/ssl-secrets/ssl-strategoxt-org.key";
      extraConfig =
        ''
          SSLCertificateChainFile /root/ssl-secrets/startssl-class1.pem
          SSLCACertificateFile /root/ssl-secrets/startssl-ca.pem
        '';
    };

in

rec {
  require = [ ];

  services = {

    httpd = {
      enable = true;
      multiProcessingModule = "worker";
      logPerVirtualHost = true;
      adminAddr = "e.dolstra@tudelft.nl";
      hostName = "localhost";

      extraModules = ["deflate"];
      extraConfig =
        ''
          AddType application/nix-package .nixpkg

          <Location /server-status>
            SetHandler server-status
            Allow from 127.0.0.1 # If using a remote host for monitoring replace 127.0.0.1 with its IP.
            Order deny,allow
            Deny from all
          </Location>

          ExtendedStatus On

          StartServers 15
        '';

      phpOptions =
        ''
          #max_execution_time = 2
          memory_limit = "128M"
          max_input_time = 300
        '';

      virtualHosts = [

        { # Catch-all site.
          hostName = "old.nixos.org";
          globalRedirect = "http://nixos.org/";
        }

        { hostName = "buildfarm.st.ewi.tudelft.nl";
          documentRoot = cleanSource ./webroot;
          enableUserDir = true;
          extraSubservices = [
            { function = import /etc/nixos/services/subversion;
              urlPrefix = "";
              toplevelRedirect = false;
              dataDir = "/data/subversion";
              notificationSender = "svn@buildfarm.st.ewi.tudelft.nl";
              organisation = {
                name = "Software Engineering Research Group, TU Delft";
                url = http://www.st.ewi.tudelft.nl/;
                logo = "/serg-logo.png";
              };
            } /*
            { function = import /etc/nixos/services/subversion;
              id = "ptg";
              urlPrefix = "/ptg";
              dataDir = "/data/subversion-ptg";
              notificationSender = "svn@buildfarm.st.ewi.tudelft.nl";
              organisation = {
                name = "Software Engineering Research Group, TU Delft";
                url = http://www.st.ewi.tudelft.nl/;
                logo = "/serg-logo.png";
              };
            } */
            { serviceType = "zabbix";
              urlPrefix = "/zabbix";
            }
          ];
          servedDirs = [
            { urlPath = "/releases";
              dir = "/data/webserver/dist";
            }
          ];
        }

        strategoxtVHostConfig

        (strategoxtVHostConfig // strategoxtSSLConfig)

        { hostName = "www.strategoxt.org";
          serverAliases = ["www.stratego-language.org"];
          globalRedirect = "http://strategoxt.org/";
        }

        { hostName = "svn.strategoxt.org";
          globalRedirect = "https://svn.strategoxt.org/";
        }

        ( strategoxtSSLConfig //
        { hostName = "svn.strategoxt.org";
          extraSubservices = [
            { function = import /etc/nixos/services/subversion;
              id = "strategoxt";
              urlPrefix = "";
              dataDir = "/data/subversion-strategoxt";
              notificationSender = "svn@svn.strategoxt.org";
              organisation = {
                name = "Stratego/XT";
                url = http://strategoxt.org/;
                logo = http://strategoxt.org/pub/Stratego/StrategoLogo/StrategoLogoTextlessWhite-100px.png;
              };
            }
          ];
        })

        { hostName = "program-transformation.org";
          serverAliases = ["www.program-transformation.org"];
          extraSubservices = [
            { function = import /etc/nixos/services/twiki;
              startWeb = "Transform/WebHome";
              dataDir = "/data/pt-wiki/data";
              pubDir = "/data/pt-wiki/pub";
              twikiName = "Program Transformation Wiki";
              registrationDomain = "ewi.tudelft.nl";
            }
          ];
        }

        { hostName = "releases.strategoxt.org";
          documentRoot = "/data/webserver/dist/strategoxt2";
        }

        { hostName = "syntax-definition.org";
          serverAliases = ["www.syntax-definition.org"];
          extraSubservices = [
            { function = import /etc/nixos/services/twiki;
              startWeb = "Sdf/WebHome";
              dataDir = "/data/pt-wiki/data";
              pubDir = "/data/pt-wiki/pub";
              twikiName = "Syntax Definition Wiki";
              registrationDomain = "ewi.tudelft.nl";
            }
          ];
        }

        { hostName = "hydra.nixos.org";
          logFormat = ''"%h %l %u %t \"%r\" %>s %b %D"'';
          extraConfig = ''
            TimeOut 900

            <Proxy *>
              Order deny,allow
              Allow from all
            </Proxy>

            ProxyRequests     Off
            ProxyPreserveHost On
            ProxyPass         /       http://lucifer:3000/ retry=5 disablereuse=on
            ProxyPassReverse  /       http://lucifer:3000/

            <Location />
              SetOutputFilter DEFLATE
              BrowserMatch ^Mozilla/4\.0[678] no-gzip\
              BrowserMatch \bMSI[E] !no-gzip !gzip-only-text/html
              SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary
              SetEnvIfNoCase Request_URI /api/ no-gzip dont-vary
              SetEnvIfNoCase Request_URI /download/ no-gzip dont-vary
            </Location>

          '';
        }

        { hostName = "hydra-test.nixos.org";
          logFormat = ''"%h %l %u %t \"%r\" %>s %b %D"'';
          extraConfig = ''
            <Proxy *>
              Order deny,allow
              Allow from all
            </Proxy>

            ProxyRequests     Off
            ProxyPreserveHost On
            ProxyPass         /       http://wendy:4000/ retry=5 disablereuse=off
            ProxyPassReverse  /       http://wendy:4000/
          '';
        }

        { hostName = "planet.strategoxt.org";
          serverAliases = ["planet.stratego.org"];
          documentRoot = "/home/karltk/public_html/planet";
        }

        { hostName = "mturk.nixos.org";
          extraConfig = ''
            <Proxy *>
              Order deny,allow
              Allow from all
            </Proxy>

            ProxyRequests     Off
            ProxyPreserveHost On
            ProxyPass         /  http://wendy/~mturk/ retry=5
            ProxyPassReverse  /  http://wendy/~mturk/
          '';
        }

        { hostName = "mturk-view.nixos.org";
          extraConfig = ''
            Redirect permanent / http://nixos.org/mturk/
          '';
        }

        { hostName = "mturk-view-sandbox.nixos.org";
          extraConfig = ''
            Redirect permanent / http://nixos.org/mturk-sandbox/
          '';
        }

      ];
    };

    zabbixAgent.enable = true;

    zabbixServer.enable = true;
    zabbixServer.dbServer = "wendy";
    zabbixServer.dbPassword = import ./zabbix-password.nix;

  };

  environment.systemPackages = [ zabbixMail ];

}
