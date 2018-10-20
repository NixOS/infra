{ lib, config, ... }:
let
  inherit (lib) mkIf;

  subnetIP = "${config.macosGuest.network.interiorNetworkPrefix}.0";
  routerIP = "${config.macosGuest.network.interiorNetworkPrefix}.1";
  guestIP = "${config.macosGuest.network.interiorNetworkPrefix}.2";
  broadcastIP = "${config.macosGuest.network.interiorNetworkPrefix}.255";
in {
  config = mkIf config.macosGuest.enable {
    boot.kernel.sysctl."net.ipv4.conf.all.forwarding" = true;
    boot.kernel.sysctl."net.ipv4.conf.default.forwarding" = true;

    networking.firewall.extraCommands = ''
      ip46tables -A nixos-fw -i tap0 -p udp --dport 53 -j nixos-fw-accept # knot dns / kresd
    '';

    networking.firewall.allowedTCPPorts = [
      2200 # forwarded port to the guest
    ];

    networking.nat = {
      enable = true;
      externalInterface = config.macosGuest.network.externalInterface;
      internalInterfaces = [
        "tap0"
      ];
      internalIPs = [
        "${subnetIP}/24"
      ];
      forwardPorts = [
        {
          destination = "${guestIP}:22";
          proto = "tcp";
          sourcePort = 2200;
        }
      ];
    };

    networking.interfaces."tap0" = {
      virtual = true;
      ipv4.addresses = [
        {
          address = routerIP;
          prefixLength = 24;
        }
      ];
    };

    services.dhcpd4 = {
      enable = true;
      interfaces = [ "tap0" ];
      extraConfig = ''
        authoritative;
        subnet ${subnetIP} netmask 255.255.255.0 {
          option routers ${routerIP};
          option broadcast-address ${broadcastIP};
          option domain-name-servers ${routerIP};

          group {
            host builder {
              hardware ethernet ${config.macosGuest.guest.MACAddress};
              fixed-address ${guestIP};
            }
          }
        }
      '';
    };

    services.kresd = {
      enable = true;
      interfaces = [ "::1" "127.0.0.1" routerIP ];
      extraConfig = ''
        modules = {
          'policy',   -- Block queries to local zones/bad sites
          'stats',    -- Track internal statistics
          'predict',  -- Prefetch expiring/frequent records
        }
        -- Smaller cache size
        cache.size = 10 * MB
      '';
    };
  };
}
