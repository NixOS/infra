flakes:

let
  makeMac = { ip, extra }: {
    deployment = {
      targetHost = ip;
    };
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
        zvolName = "rpool/mac-hdd-2-initial-setup-startup-script.img";
        ovmfCodeFile = ../macs/dist/OVMF_CODE.fd;
        ovmfVarsFile = ../macs/dist/OVMF_VARS-1024x768.fd;
        guestConfigDir = ../macs/guest;
      };
    };
    imports = [
      ../macs/host
      extra
    ];
  };

in {
  defaults = {
    imports = [
      ../modules/wireguard.nix
      ../modules/prometheus
      flakes.dwarffs.nixosModules.dwarffs
      { system.configurationRevision = flakes.self.rev
          or (throw "Cannot deploy from an unclean source tree!");
        nixpkgs.overlays = [ flakes.nix.overlay ];
      }
    ];
  };

  hydra = { deployment.targetHost = "hydra.ewi.tudelft.nl"; imports = [ ./build-machines-dell-1950.nix ]; };
  lucifer = { deployment.targetHost = "lucifer.ewi.tudelft.nl"; imports = [ ./lucifer.nix ]; };
  wendy = { deployment.targetHost = "wendy.ewi.tudelft.nl"; imports = [ ./wendy.nix ]; };
  ike = { deployment.targetHost = "ike.ewi.tudelft.nl"; imports = [ ./build-machines-dell-r815.nix ]; };

  chef = {
    imports = [./chef.nix ];
  };

  eris = import ./eris.nix;

  ceres = {
    system.configurationRevision = flakes.self.rev;
    imports =
      [ ./ceres.nix
        flakes.hydra.nixosModules.hydra
      ];
  };

  haumea = {
    system.configurationRevision = flakes.self.rev;
    imports = [ ./haumea.nix ];
  };

  mac1 = makeMac {
    ip = "10.254.2.1";
    extra = {
      imports = [
        ../macs/nodes/mac1.nix
      ];
    };
  };

  mac2 = makeMac {
    ip = "10.254.2.2";
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
