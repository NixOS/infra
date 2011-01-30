{ config, pkgs, ... }:

{
  boot.kernelModules = [ "coretemp" ];

  environment.systemPackages = 
    [ pkgs.emacs pkgs.subversion pkgs.sysstat pkgs.hdparm pkgs.sdparm pkgs.lsiutil 
      pkgs.htop pkgs.sqlite
    ];

  services.sshd.enable = true;

  boot.postBootCommands =
    ''
      echo 60 > /proc/sys/kernel/panic
    '';

  nix.useChroot = true;

  nix.nrBuildUsers = 100;

  nix.extraOptions =
    ''
      fsync-metadata = false
      use-sqlite-wal = false
    '';

  services.zabbixAgent.enable = true;
  services.zabbixAgent.server = "192.168.1.5,127.0.0.1,130.161.158.181";
  services.zabbixAgent.extraConfig =
    ''
      UserParameter=hardware.temp.cpu.average,cat /sys/devices/platform/coretemp.*/temp1_input | ${pkgs.perl}/bin/perl -e 'while (<>) { $n++; $sum += $_; }; print $sum / $n / 1000;'
      UserParameter=vm.memory.dirty,echo $((1024 * $(cat /proc/meminfo | sed 's/Dirty: *\([0-9]\+\) kB/\1/; t; d')))
    '';

  networking.defaultMailServer = {
    directDelivery = true;
    hostName = "smtp.tudelft.nl";
    domain = "st.ewi.tudelft.nl";
  };
}
