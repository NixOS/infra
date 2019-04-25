host:
{ lib, ... }:
let
  network = 16;
  hosts = {
    bastion = {
      ip = "10.254.1.1";
      endoint = "bastion.nixos.org";
      port = 51820;
      publicKey = "nG7I9gegJIynKOZ6tzpvmLdCZ/xScTgRZeFvYLFyil4=";
    };
    
    mac1 = {
      ip = "10.254.2.1";
      # publicKey = "abc123";
    };
  };

  peerable = selfHost: lib.filterAttrs (hostname: hostcfg:
    (hostname != selfHost)
    && (hostcfg ? "publicKey")
  ) hosts;
in {
  networking.wireguard.interfaces.wg0 = {
    ips = [ "${hosts."${host}".ip}/${toString network}" ];
    privateKeyFile = "/etc/wireguard/private.key";
    generatePrivateKeyFile = true;
    listenPort = hosts."${host}".port or null;
    
    peers = lib.mapAttrsToList (hostname: hostcfg:
      {
        inherit (hostcfg) publicKey;
	allowedIPs = [ "${hostcfg.ip}/32" ];
      } // (lib.optionalAttrs (hostcfg ? endpoint) {
      	persistentKeepalive = 60;
        inherit (hostcfg) endpoint;
      })
    ) (peerable host);
  };
}