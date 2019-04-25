{ lib, config, ... }:
let
  inherit (lib) mkIf;
in {
  config = mkIf config.monitorama.enable {
    networking.firewall.allowedTCPPorts = [ 9111 ];
    services.nginx = {
      enable = true;
      virtualHosts = {
        default = {
          default = true;
          listen = [ { addr = "0.0.0.0"; port = 9111; } ];
          locations = builtins.mapAttrs (name: value: { proxyPass = value; }) config.monitorama.hosts;
        };
      } // (
      builtins.mapAttrs (name: value: {
          listen = [ { addr = "0.0.0.0"; port = 9111; } ];
          locations."/metrics".proxyPass = value;
        })
        config.monitorama.hosts
        );
    };
  };
}
