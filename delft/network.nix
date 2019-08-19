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
  hydra = { deployment.targetHost = "hydra.ewi.tudelft.nl"; imports = [ ./build-machines-dell-1950.nix ]; };
  lucifer = { deployment.targetHost = "lucifer.ewi.tudelft.nl"; imports = [ ./lucifer.nix ]; };
  wendy = { deployment.targetHost = "wendy.ewi.tudelft.nl"; imports = [ ./wendy.nix ]; };
  ike = { deployment.targetHost = "ike.ewi.tudelft.nl"; imports = [ ./build-machines-dell-r815.nix ]; };
  packet-epyc-1 = { deployment.targetHost = "147.75.198.47"; imports = [ ./packet/packet-epyc-1.nix ./build-machines-common.nix ]; };
  packet-t2-4 = { deployment.targetHost = "147.75.98.145"; imports = [ ./packet/packet-t2-4.nix ./build-machines-common.nix ]; };
  chef = import ./chef.nix;
  eris = import ./eris.nix;
  ceres = import ./ceres.nix;

  mac1 = makeMac {
    ip = "10.254.2.1";
    extra = {
      imports = [
        ../macs/nodes/mac1.nix
        ../modules/wireguard.nix
      ];
    };
  };

  mac2 = makeMac {
    ip = "10.254.2.2";
    extra = {
      imports = [
        ../macs/nodes/mac2.nix
        ../modules/wireguard.nix
      ];
    };
  };

  mac3 = makeMac {
    ip = "10.254.2.3";
    extra = {
      imports = [
        ../macs/nodes/mac3.nix
        ../modules/wireguard.nix
        ({ config, lib, ... }: {
          monitorama.enable = true;
          monitorama.hosts = let
            nums = lib.lists.range 1 9;
            paths = num: {
              "mac${toString num}-host" = "http://192.168.2.${toString (num + 100)}:9100/metrics";
              "mac${toString num}-guest" = "http://192.168.2.${toString (num + 100)}:9101/metrics";
            };
            overrides = {
              "mac3-guest" = "http://${config.macosGuest.network.interiorNetworkPrefix}.2:9100/metrics";
            };
          in (builtins.foldl' (a: b: a // b) {} (builtins.map paths nums)) // overrides;
        })
      ];
    };
  };

  mac4 = makeMac {
    ip = "10.254.2.4";
    extra = {
      imports = [
        ../macs/nodes/mac4.nix
        ../modules/wireguard.nix
      ];
    };
  };

  mac5 = makeMac {
    ip = "10.254.2.5";
    extra = {
      imports = [
        ../macs/nodes/mac5.nix
        ../modules/wireguard.nix
      ];
    };
  };

  mac6 = makeMac {
    ip = "10.254.2.6";
    extra = {
      imports = [
        ../macs/nodes/mac6.nix
        ../modules/wireguard.nix
      ];
    };
  };

  mac7 = makeMac {
    ip = "10.254.2.7";
    extra = {
      imports = [
        ../macs/nodes/mac7.nix
        ../modules/wireguard.nix
      ];
    };
  };

  mac8 = makeMac {
    ip = "10.254.2.8";
    extra = {
      imports = [
        ../macs/nodes/mac8.nix
        ../modules/wireguard.nix
      ];
    };
  };

  # mac9 never booted
}
