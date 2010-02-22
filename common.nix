{ config, pkgs, ... }:

{
  boot.kernelModules = [ "coretemp" ];

  environment.systemPackages = [ pkgs.emacs pkgs.subversion ];

  services.sshd.enable = true;

  boot.postBootCommands =
    ''
      echo 60 > /proc/sys/kernel/panic
    '';

  nix.useChroot = true;

  nix.extraOptions =
    ''
      fsync-metadata = true
    '';

  services.zabbixAgent.enable = true;
  services.zabbixAgent.server = "192.168.1.5,127.0.0.1";
  services.zabbixAgent.extraConfig =
    ''
      UserParameter=hardware.temp.cpu.average,cat /sys/devices/platform/coretemp.*/temp1_input | ${pkgs.perl}/bin/perl -e 'while (<>) { $n++; $sum += $_; }; print $sum / $n / 1000;'
    '';
}
