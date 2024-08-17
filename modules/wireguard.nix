{ config, lib, ... }:
let
  inherit (builtins.fromTOML (builtins.readFile ./wireguard-hosts.toml)) network hosts;

  peerable =
    selfHost:
    lib.filterAttrs (hostname: hostcfg: (hostname != selfHost) && (hostcfg ? "publicKey")) hosts;
in
lib.mkMerge [
  (lib.mkIf (hosts."${config.networking.hostName}" ? "port") {
    networking.firewall.allowedUDPPorts = [ hosts."${config.networking.hostName}".port ];
  })
  {
    networking.wireguard.interfaces.wg0 = {
      ips = [ "${hosts."${config.networking.hostName}".ip}/${toString network}" ];
      privateKeyFile = "/etc/wireguard/private.key";
      generatePrivateKeyFile = true;
      listenPort = hosts."${config.networking.hostName}".port or null;

      peers = lib.mapAttrsToList (
        _hostname: hostcfg:
        {
          inherit (hostcfg) publicKey;
          allowedIPs = [ "${hostcfg.ip}/32" ];
        }
        // (lib.optionalAttrs (hostcfg ? "endpoint") {
          endpoint = "${hostcfg.endpoint}:${toString hostcfg.port}";
          persistentKeepalive = 60;
        })
      ) (peerable config.networking.hostName);
    };

    # networkd-wait-online sometimes fails to notice that the interface is up,
    # since it's not managing it.
    systemd.network.wait-online.ignoredInterfaces = [ "wg0" ];
  }
]
