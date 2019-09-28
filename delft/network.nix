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
    imports = [ ../modules/wireguard.nix ];
  };
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
    ip = "mac1";
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
    ip = "mac3";
    extra = {
      imports = [
        ../macs/nodes/mac3.nix
      ];
    };
  };

  mac4 = makeMac {
    ip = "mac4";
    extra = {
      imports = [
        ../macs/nodes/mac4.nix
      ];
    };
  };

  mac5 = makeMac {
    ip = "mac5";
    extra = {
      imports = [
        ../macs/nodes/mac5.nix
      ];
    };
  };

  mac6 = makeMac {
    ip = "mac6";
    extra = {
      imports = [
        ../macs/nodes/mac6.nix
      ];
    };
  };

  mac7 = makeMac {
    ip = "mac7";
    extra = {
      imports = [
        ../macs/nodes/mac7.nix
      ];
    };
  };

  mac8 = makeMac {
    ip = "mac8";
    extra = {
      imports = [
        ../macs/nodes/mac8.nix
      ];
    };
  };

  mac9 = makeMac {
    ip = "mac9";
    extra = {
      imports = [
        ../macs/nodes/mac8.nix
      ];
    };
  };
}
