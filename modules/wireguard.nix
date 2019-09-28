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

    chef = {
      ip = "10.254.1.2";
#      endpoint = "hydra.nixos.org";
#      port = 51820;
      publicKey = "Y/RHgJ7Znh9vyWlXd2g8p9Zz1YEE50TYgqDduluhjmU=";
    };

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

    ike = {
      ip = "10.254.1.5";
      endpoint = "131.180.119.70";
      port = 51820;
      publicKey = "0Gnpua+K9Ms4m56j99KLrHNTbqDBLLp96eY9vmJbozQ=";
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

    wendy = {
      ip = "10.254.1.8";
      enpdoint = "131.180.119.77";
      port = 51820;
    };

    packet-epyc-1 = {
      ip = "10.254.1.9";
      enpdoint = "147.75.198.47";
      port = 51820;
    };

    packet-t2-4 = {
      ip = "10.254.1.10";
      enpdoint = "147.75.98.145";
      port = 51820;
    };

    mac1 = {
      ip = "10.254.2.1";
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
    mac9 = {
      ip = "10.254.2.9";
      publicKey = "i3fOonYJsDhhF8YXrWfaLQgb4J3OphOs7DTTCGTDNCQ=";
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
