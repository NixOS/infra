{
  pkgs,
  lib,
  ...
}:

let
  nft-asblock = pkgs.callPackage ./nft-asblock { };

  asblocks = [
    45102 # ALIBABA-CN-NET
    132203 # TENCENT-NET-AP-CN
  ];
in

{
  networking.nftables = {
    enable = true;
    tables."abuse" = {
      family = "inet";
      content = ''
        set blocked4 {
          type ipv4_addr;
          flags interval, timeout;
          auto-merge;
          timeout 6h;
        }
        set blocked6 {
          type ipv6_addr;
          auto-merge;
          flags interval, timeout;
          timeout 6h;
        }
        chain input-abuse {
          type filter hook input priority filter - 5;

          ip saddr @blocked4 counter drop;
          ip6 saddr @blocked6 counter drop;
        }
      '';
    };
  };

  systemd.services.nft-asblock = {
    path = with pkgs; [ nftables ];
    serviceConfig = {
      AmbientCapabilities = [ "CAP_NET_ADMIN" ];
      DynamicUser = true;
      User = "nft-asblock";
      Group = "nft-asblock";
      ExecStart = toString (
        [
          (lib.getExe nft-asblock)
        ]
        ++ asblocks
      );
      StateDirectory = "nft-asblock";
    };
  };

}
