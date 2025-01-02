{
  networking.useDHCP = false;

  systemd.network = {
    enable = true;
    networks = {
      "99-autoconfig" = {
        matchConfig = {
          Kind = "!*";
          Type = "ether";
        };
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
      };
    };
  };
}
