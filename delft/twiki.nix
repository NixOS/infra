/* Configuration for the NixOS container that runs strategoxt.org,
   program-transformation.org and syntax-definition.org. TWiki
   requires an old version of Nixpkgs, so we put it into a container.

   The TWiki data lives in /data/pt-wiki in the container, which
   itself resides in /var/lib/containers/twiki.

   To rebuild the container (from wendy):

   $ NIX_PATH=nixpkgs=channel:nixos-17.03 nixos-container update twiki --config-file /etc/nixos/nixos-org-configurations/delft/twiki.nix

   To login to the container:

   $ nixos-container root-login twiki

*/

{ config, pkgs, ... }:

{

  networking.firewall.allowedTCPPorts = [ 80 ];

  services = {

    httpd = {
      enable = true;
      adminAddr = "edolstra@gmail.com";
      hostName = "localhost";

      virtualHosts = [

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
        }

        { hostName = "program-transformation.org";
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

        { hostName = "syntax-definition.org";
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

      ];

    };

  };

}