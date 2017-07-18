{ config, pkgs, ... }:

with pkgs.lib;

let

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
      adminAddr = "e.dolstra@tudelft.nl";
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
          globalRedirect = "http://nixos.org/";
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
            /*
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
            */
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

        { hostName = "planet.strategoxt.org";
          serverAliases = ["planet.stratego.org"];
          documentRoot = "/home/karltk/public_html/planet";
        }
      ];
    };

  };
}
