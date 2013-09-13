{ config, pkgs, ... }:

{
  require = [ ./build-machines-common.nix ];

  nixpkgs.system = "x86_64-linux";

  boot.initrd.kernelModules = [ "mptsas" ];
  boot.kernelModules = [ "acpi-cpufreq" "kvm-intel" ];

  swapDevices = [ { label = "swap"; } ];

  nix.maxJobs = 8;

  services.httpd.enable = true;
  services.httpd.adminAddr = "foo@example.org";

  networking.firewall.enable = false;
  networking.firewall.allowedTCPPorts = [ 80 ];
  networking.firewall.rejectPackets = true;
  networking.firewall.allowPing = true;

  networking.bridges.veno1.interfaces = [ config.system.build.mainPhysicalInterface ];

  system.build.mainVirtualInterface = "veno1";

  virtualisation.libvirtd.enable = true;

  /*
  networking.localCommands =
    ''
      # Enable IPv6 forwarding.  Nova/radvd requires this.
      echo 1 > /proc/sys/net/ipv6/conf/all/forwarding

      # Urgh.  The Linux kernel disables processing of router
      # advertisements if forwarding is enabled, so we have to
      # configure manually.  Apparently in newer kernels, we can set
      # /proc/sys/net/ipv6/conf/all/accept_ra to 2 instead.
      ip -6 addr add 2001:610:685:1:222:19ff:fe55:bf2e/64 dev veno1 || true
      ip -6 route add default via fe80::204:23ff:fedf:f7bf dev veno1 || true
    '';
  */
}
