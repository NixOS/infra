{ config, pkgs, ... }:

{
  require = [ ./build-machines-common.nix ];

  nixpkgs.system = "x86_64-linux";

  boot.initrd.kernelModules = [ "mptsas" ];
  boot.kernelModules = [ "acpi-cpufreq" "kvm-intel" ];

  nix.maxJobs = 8;

  services.httpd.enable = true;
  services.httpd.adminAddr = "foo@example.org";

  networking.firewall.enable = false;
  networking.firewall.allowedTCPPorts = [ 80 10050 ];
  networking.firewall.rejectPackets = true;
  networking.firewall.allowPing = true;

  networking.bridges.veth0.interfaces = [ "eth0" ];

  virtualisation.libvirtd.enable = true;

  virtualisation.nova.enableSingleNode = true;
}
