{ config, pkgs, ... }:

{
  require = [ ./build-machines-common.nix ];

  nixpkgs.system = "x86_64-linux";

  boot.initrd.kernelModules = [ "mptsas" ];
  boot.kernelModules = [ "acpi-cpufreq" "kvm-intel" ];

  swapDevices = [ { label = "swap"; } ];

  nix.maxJobs = 8;

  /*
  services.httpd.enable = true;
  services.httpd.adminAddr = "foo@example.org";

  networking.firewall.enable = false;
  networking.firewall.allowedTCPPorts = [ 80 ];
  networking.firewall.rejectPackets = true;
  networking.firewall.allowPing = true;
  */

  /*
  networking.bridges.veno1.interfaces = [ config.system.build.mainPhysicalInterface ];

  # Libvirt dynamically creates vnet* interfaces to connect interfaces
  # to the veno1 bridge.  So after restarting veno1, we have to add
  # those interfaces back in.
  systemd.services.veno1.postStart =
    ''
      for iface in $(cd /sys/class/net && echo vnet*); do
        brctl addif veno1 "$iface" || true
      done
    '';

  system.build.mainVirtualInterface = "veno1";

  virtualisation.libvirtd.enable = true;
  */
}
