{
  lib,
  ...
}:

{
  networking.nftables = {
    enable = true;
    tables."nixos-fw".content = lib.mkBefore ''
      define prometheus_inet6 = {
        2a01:4f9:3070:15e0::1,
        2a01:4f8:231:e53::1
      }
      define prometheus_inet4 = {
        37.27.99.100,
        159.69.62.224
      }
    '';
  };

  networking.firewall = {
    enable = true;

    # be a good network citizen and allow some debugging interactions
    rejectPackets = true;
    allowPing = true;

    # prevent firewall log spam from rotating the kernel ringbuffer
    logRefusedConnections = false;
  };
}
