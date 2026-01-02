{
  pkgs,
  lib,
  inputs,
  ...
}:

let
  blockedAutNums = [
    45102 # ALIBABA-CN-NET
    45899 # VNPT-AS-VN
    132203 # TENCENT-NET-AP-CN
  ];
in

{
  networking.nftables = {
    tables."abuse" = {
      family = "inet";
      content = ''
        set ipv4blocks {
          type ipv4_addr;
          flags interval;
          auto-merge;
        }
        set ipv6blocks {
          type ipv6_addr;
          auto-merge;
          flags interval;
        }
        chain input-abuse {
          type filter hook input priority filter - 5;

          ip saddr @ipv4blocks tcp dport 443 counter drop;
          ip6 saddr @ipv6blocks tcp dport 443 counter drop;
        }
      '';
    };
  };

  systemd.services.nft-prefix-import = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ nftables ];
    environment.USER_AGENT = "NixOS.org Infrastructure - infra@nixos.org";
    serviceConfig = {
      Type = "oneshot";
      AmbientCapabilities = [ "CAP_NET_ADMIN" ];
      DynamicUser = true;
      User = "nft-asblock";
      Group = "nft-asblock";
      ExecStart = toString (
        [
          (lib.getExe inputs.nft-prefix-import.packages.${pkgs.stdenv.hostPlatform.system}.default)
          "--table"
          "abuse"
          "--ipv4set"
          "ipv4blocks"
          "--ipv6set"
          "ipv6blocks"
        ]
        ++ blockedAutNums
      );
      RestrictAddressFamilies = [
        "AF_NETLINK"
        "AF_INET"
        "AF_INET6"
      ];
      StateDirectory = "nft-prefix-import";
      WorkingDirectory = "/var/lib/nft-prefix-import";
    };
  };

  systemd.timers.nft-prefix-import = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "0/6:00";
      RandomizedDelaySec = 3600;
    };
  };
}
