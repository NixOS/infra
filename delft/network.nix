flakes:

let
  networkoverlay = self: super: {
    prometheus-postgres-exporter = self.callPackage ./prometheus/postgres-exporter.nix {};
  };

  makeMac = { ip, extra, useCatalina ? false }: {
    deployment = {
      targetHost = ip;
    };

    # work around nix#3462
    documentation.nixos.enable = false;

    imports = [
      ../macs/host
      extra
      ({ lib, pkgs, ... }: {
        macosGuest = {

          enable = true;
          network = {
            interiorNetworkPrefix = "10.172.170"; #172="n", 170="x"
            externalInterface = "enp3s0f0";
            sshInterface = "wg0";
          };

          guest = {
            sockets = 1;
            cores = 2;
            threads = 2;
            memoryInMegs = 6 * 1024;
            ovmfCodeFile = ../macs/dist/OVMF_CODE.fd;
            ovmfVarsFile = ../macs/dist/OVMF_VARS-1024x768.fd;
          } // (if useCatalina then
            {
              zvolName = lib.mkForce "rpool/catalina";
              guestConfigDir = lib.mkForce ../macs/guest-catalina;
              cloverImage = (pkgs.callPackage ../macs/dist/clover-catalina {}).clover-image;
            }
          else
            {
              zvolName = "rpool/mac-hdd-2-initial-setup-startup-script.img";
              guestConfigDir = ../macs/guest;
            }
          );
        };
      })
    ];
  };
in {
  defaults = {
    documentation.nixos.enable = false;

    security.acme.acceptTerms = true;
    security.acme.email = "webmaster@nixos.org";

    imports = [
      ../modules/wireguard.nix
      ../modules/prometheus
      # flakes.dwarffs.nixosModules.dwarffs # broken by Nix 2.6
      { system.configurationRevision = flakes.self.rev
          or (throw "Cannot deploy from an unclean source tree!");
        nixpkgs.overlays = [
          flakes.nix.overlay
          networkoverlay
        ];
        nix.registry.nixpkgs.flake = flakes.nixpkgs;
        nix.nixPath = [ "nixpkgs=${flakes.nixpkgs}" ];
      }
    ];
  };

  eris = import ./eris.nix;

  haumea = {
    imports = [ ./haumea.nix ];
  };

  rhea = {
    imports = [
      ./rhea
      flakes.hydra.nixosModules.hydra
    ];
  };

  mac1 = makeMac {
    ip = "10.254.2.1";
    extra = { pkgs, lib, ... }: {
      imports = [
        ../macs/nodes/mac1.nix
      ];

      macosGuest = {
        guest = {
          zvolName = lib.mkForce "rpool/catalina";
          guestConfigDir = lib.mkForce ../macs/guest-catalina;
          cloverImage = (pkgs.callPackage ../macs/dist/clover-catalina {}).clover-image;
        };
      };
    };
  };

  mac2 = makeMac {
    ip = "10.254.2.2";
    useCatalina = false;
    extra = {
      imports = [
        ../macs/nodes/mac2.nix
      ];
    };
  };

  mac3 = makeMac {
    ip = "10.254.2.3";
    extra = {
      imports = [
        ../macs/nodes/mac3.nix
      ];
    };
  };

  mac4 = makeMac {
    ip = "10.254.2.4";
    extra = {
      imports = [
        ../macs/nodes/mac4.nix
      ];
    };
  };

  mac5 = makeMac {
    ip = "10.254.2.5";
    extra = {
      imports = [
        ../macs/nodes/mac5.nix
      ];
    };
  };

  mac6 = makeMac {
    ip = "10.254.2.6";
    extra = {
      imports = [
        ../macs/nodes/mac6.nix
      ];
    };
  };

  mac7 = makeMac {
    ip = "10.254.2.7";
    extra = {
      imports = [
        ../macs/nodes/mac7.nix
      ];
    };
  };

  mac8 = makeMac {
    ip = "10.254.2.8";
    extra = {
      imports = [
        ../macs/nodes/mac8.nix
      ];
    };
  };

  mac9 = makeMac {
    ip = "10.254.2.9";
    extra = {
      imports = [
        ../macs/nodes/mac8.nix
      ];
    };
  };
}
