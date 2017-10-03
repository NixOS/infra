{ config, pkgs, ... }:

with pkgs.lib;

let

  twikiIP = "10.233.1.2";

  proxyConfig = hostName:
    { inherit hostName;
      extraConfig =
        ''
          <Proxy *>
            Order deny,allow
            Allow from all
          </Proxy>

          ProxyRequests     Off
          ProxyPreserveHost On
          ProxyPass         /       http://${twikiIP}/ retry=5 disablereuse=on
        '';
    };

  strategoxtSSLConfig =
    { enableSSL = true;
      sslServerCert = "/root/ssl-secrets/ssl-strategoxt.org.crt";
      sslServerKey = "/root/ssl-secrets/ssl-strategoxt.org.key";
      extraConfig =
        ''
          SSLCertificateChainFile ${../nixos-org/sub.class1.server.ca.pem}
        '';
    };

in

{
  services = {

    httpd = {
      enable = true;
      logPerVirtualHost = true;
      adminAddr = "edolstra@gmail.com";
      hostName = "localhost";

      extraModules = [ "deflate" ];

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

          SSLProtocol All -SSLv2 -SSLv3
          SSLCipherSuite HIGH:!aNULL:!MD5:!EXP
          SSLHonorCipherOrder on
        '';

      servedDirs =
        [ { urlPath = "/apache-errors";
            dir = ./apache-errors;
          }
        ];

      virtualHosts = [

        { # Catch-all site.
          hostName = "old.nixos.org";
          globalRedirect = "https://nixos.org/";
        }

        { hostName = "buildfarm.st.ewi.tudelft.nl";
          documentRoot = cleanSource ./webroot;
          enableUserDir = true;
          extraSubservices = [
            /*
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
            }
            */
            /*
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
            }
            */
          ];
          servedDirs = [
            { urlPath = "/releases";
              dir = "/data/webserver/dist";
            }
          ];
        }

        (proxyConfig "strategoxt.org")

        (proxyConfig "strategoxt.org" // strategoxtSSLConfig)

        (proxyConfig "program-transformation.org")

        (proxyConfig "syntax-definition.org")

        { hostName = "www.strategoxt.org";
          serverAliases = ["www.stratego-language.org"];
          globalRedirect = "http://strategoxt.org/";
        }

        { hostName = "www.program-transformation.org";
          globalRedirect = "http://program-transformation.org/";
        }

        { hostName = "svn.strategoxt.org";
          globalRedirect = "https://svn.strategoxt.org/";
        }

        { hostName = "releases.strategoxt.org";
          documentRoot = "/data/webserver/dist/strategoxt2";
        }

        { hostName = "planet.strategoxt.org";
          serverAliases = ["planet.stratego.org"];
          documentRoot = "/home/karltk/public_html/planet";
        }

      ];
    };

  };
}
