{ config, pkgs, ... }:

with pkgs.lib;

let

  machines = import ./machines.nix pkgs.lib;

  machine = findSingle (m: m.hostName == config.deployment.targetHost) {} {} machines;

  iface = "enx" + replaceChars [":"] [""] machine.ethernetAddress;

in

{
  config = mkIf (machine != {}) {

    # Name network interfaces after their MAC address.
    services.udev.extraRules =
      ''
        SUBSYSTEM!="net", GOTO="my_end"
        IMPORT{builtin}="net_id"
        KERNEL=="vnet*", GOTO="my_end"
        NAME=="", ENV{ID_NET_NAME_MAC}!="", NAME="$env{ID_NET_NAME_MAC}"
        LABEL="my_end"
      '';

    #networking.useDHCP = false;

    networking.domain = "ewi.tudelft.nl";

    networking.defaultGateway = mkDefault "131.180.119.1";

    networking.nameservers = mkDefault [ "130.161.180.1" "130.161.180.65" "131.155.0.38" ];

    networking.extraHosts =
      ''
        2001:610:685:1:216:3eff:fe00:1 tweek
        2001:610:685:1:216:3eff:fe00:5 meerkat
        2001:610:685:1:216:3eff:fe00:7 beastie
        2001:610:685:1:216:3eff:fe00:8 demon
      '';

    system.build.mainPhysicalInterface = iface;

    networking.interfaces = listToAttrs (singleton (nameValuePair (config.system.build.mainVirtualInterface or config.system.build.mainPhysicalInterface)
      { ipAddress = machine.ipAddress;
        prefixLength = 25;
      }));

  };
}
