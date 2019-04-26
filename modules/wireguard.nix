{ config, lib, ... }:
let
  network = 16;
  hosts = {
    bastion = {
      ip = "10.254.1.1";
      endpoint = "bastion.nixos.org";
      port = 51820;
      publicKey = "nG7I9gegJIynKOZ6tzpvmLdCZ/xScTgRZeFvYLFyil4=";
    };

    chef = {
      ip = "10.254.1.2";
      endpoint = "hydra.nixos.org";
      port = 51820;
      publicKey = "Y/RHgJ7Znh9vyWlXd2g8p9Zz1YEE50TYgqDduluhjmU=";
    };

    mac1 = {
      ip = "10.254.2.1";
      publicKey = "IiGbZ3l+IYWP/nOjPBhUL0oBh2XJAtUD5DToM9FhTTE=";
    };
    mac2 = {
      ip = "10.254.2.2";
      publicKey = "igZp34acbeIStPF1bJUnzUSqfnMAuFusBPWCUhd5h08=";
    };
    mac3 = {
      ip = "10.254.2.3";
      publicKey = "4q9mQEsYADzraTNSowLME/OC0RDLCIM25Vanixz771c=";
    };
    mac4 = {
      ip = "10.254.2.4";
      publicKey = "Les8giS7Dx6qVUMmHe6xXweRCsiRNG6VYVKxoNuSIzI=";
    };
    mac5 = {
      ip = "10.254.2.5";
      publicKey = "M0e3nR/y5V5J9txmxcOsc0olhanQtHFBe5jwNNMDjRk=";
    };
    mac6 = {
      ip = "10.254.2.6";
      publicKey = "BJdCRAyaipdL6X+sl4ZM8594h/fnbdLT+YtFbRiVnic=";
    };
    mac7 = {
      ip = "10.254.2.7";
      publicKey = "j+DFm60vy4vj1hsMBuo3qVpFsmdLstDI+GbCOZNkKUU=";
    };
    mac8 = {
      ip = "10.254.2.8";
      publicKey = "fii4V76RpLngPiqa1x4mev4Cbon0WopKlOcfgB4VBVs=";
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
