{ config, lib, ... }:
let
  network = 16;
  hosts = {
    bastion = {
      ip = "10.254.1.1";

      # wg won't retry resolution if it fails... so
      # hard-code the IP to bastion.nixos.org so we don't lock
      # ourselves out.
      endpoint = "34.254.208.229";
      port = 51820;
      publicKey = "nG7I9gegJIynKOZ6tzpvmLdCZ/xScTgRZeFvYLFyil4=";
    };

    # tombstone: 10.254.1.2 chef

    ceres = {
      ip = "10.254.1.3";
      endpoint = "46.4.66.184";
      port = 51820;
      publicKey = "wkUjkjJtJ9yC1xh2pSbTfyuPkeUnvgxGIHFKxVCGJT8=";
    };

    eris = {
      ip = "10.254.1.4";
      endpoint = "138.201.32.77";
      port = 51820;
      publicKey = "H/Y+sbNETKZugxGFbOS0m5BSr28jRDL19U37wEw07D8=";
    };

    hydra = {
      ip = "10.254.1.6";
      endpoint = "131.180.119.69";
      port = 51820;
      publicKey = "daWQGiSHeWX1aELsppFoq740geXwIjGCLdmdQWC0Ymg=";
    };

    lucifer = {
      ip = "10.254.1.7";
      endpoint = "131.180.119.73";
      port = 51820;
    };

    haumea = {
      ip = "10.254.1.9";
      endpoint = "46.4.89.205";
      port = 51820;
      publicKey = "Fb41wGKT1TdC4MG5i2NRx6yduddmqm+N+UOtqtDuBG4=";
    };

    mac1 = {
      ip = "10.254.2.1";
      publicKey = "ZIzROtHaFWjrhhdXAE8Tq+EhUsSIURLcwsISfudndTk=";
    };
    mac2 = {
      ip = "10.254.2.2";
      publicKey = "m0xJg1OBZIqPu8maxpldLQ1Y39aPS3cnj7hqpVUSuFg=";
    };
    mac3 = {
      ip = "10.254.2.3";
      publicKey = "6urTLKp3ihXw0fy4ImhpiQu/sOxrJYewtg2cbT3jv3g=";
    };
    mac4 = {
      ip = "10.254.2.4";
      publicKey = "ojkldeD0xJw54nAeGSHQw7BMSXnc6c2e6GP4nJ/1xEo=";
    };
    mac5 = {
      ip = "10.254.2.5";
      publicKey = "UgbjJz7BPlD5oDNPr1Bpr4XqeuoL9G5+oUDyU9EVYgg=";
    };
    mac6 = {
      ip = "10.254.2.6";
      publicKey = "5t67sluyRwuDXeY17CG7sbpt0gZNybHzvJYd7NAESis=";
    };
    mac7 = {
      ip = "10.254.2.7";
      publicKey = "q/8YvHa/M0Epyqflp+fEXvBmJuOBaBJPcaAkScCYvHA=";
    };
    mac8 = {
      ip = "10.254.2.8";
      publicKey = "aw/8/5oEn0cZa/WnUE7E7MEukDvzUzaAUEL6PMhLFmE=";
    };

    macofborg1 = {
      ip = "10.254.2.51";
      publicKey = "RPD07xoZYB3aq9hS4pX+qnCHwSbNunK69HGdf8pRtCQ=";
    };

    mac-m1-1 = {
      ip = "10.254.2.101";
      publicKey = "r9EEig5zzGS+MlMqK1jCzXB4Rm11Q/c812i7dxGj8gQ=";
    };
    mac-m1-2 = {
      ip = "10.254.2.102";
      publicKey = "J0JajIlwirjrry4QsuVzzyyWSGesQWHk16IR99rcwjY=";
    };
    mac-m1-3 = {
      ip = "10.254.2.103";
      publicKey = "E/eHbib8pEnPmT6nWjXlv3H5Ww1DfWxZdbz+Cn+jCX0=";
    };
    mac-m1-4 = {
      ip = "10.254.2.104";
      publicKey = "qQ0LO8kU+zFPxCk7JBD9OrfGS3Ryl08ePyF+KQxGl2U=";
    };
    mac-m1-5 = {
      ip = "10.254.2.105";
      publicKey = "5VWVUb/fiZmAJqCfqMPH2yIa8xze6hEU11ZKYPOtQyQ=";
    };
    mac-m1-6 = {
      ip = "10.254.2.106";
      publicKey = "S20ha1NoMUgR67696vi7hmSdSxK/GJM550S0uR2odlA=";
    };

    webserver = {
      ip = "10.254.3.1";
      publicKey = "/N5//y0elGZdeekUv+IzKZiZ9wcKSOHc2bHmPU8FaCM=";
      enpdoint = "54.217.220.47";
      port = 51820;
    };
  };

  peerable = selfHost: lib.filterAttrs (hostname: hostcfg:
    (hostname != selfHost)
    && (hostcfg ? "publicKey")
  ) hosts;
in lib.mkMerge [
  (lib.mkIf (hosts."${config.networking.hostName}" ? "port") {
    networking.firewall.allowedUDPPorts = [ hosts."${config.networking.hostName}".port ];
  })
  {
    networking.wireguard.interfaces.wg0 = {
      ips = [ "${hosts."${config.networking.hostName}".ip}/${toString network}" ];
      privateKeyFile = "/etc/wireguard/private.key";
      generatePrivateKeyFile = true;
      listenPort = hosts."${config.networking.hostName}".port or null;

      peers = lib.mapAttrsToList (hostname: hostcfg:
        {
          inherit (hostcfg) publicKey;
          allowedIPs = [ "${hostcfg.ip}/32" ];
        } // (lib.optionalAttrs (hostcfg ? "endpoint") {
          endpoint = "${hostcfg.endpoint}:${toString hostcfg.port}";
          persistentKeepalive = 60;
        })
      ) (peerable config.networking.hostName);
    };
  }
]
