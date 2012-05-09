{ config, pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages_3_2;
  
  boot.kernelModules = [ "coretemp" ];

  boot.supportedFilesystems = [ "nfs" ];

  boot.initrd.kernelModules = [ "ext4" ];

  environment.systemPackages = 
    [ pkgs.emacs pkgs.subversion pkgs.sysstat pkgs.hdparm pkgs.sdparm # pkgs.lsiutil 
      pkgs.htop pkgs.sqlite pkgs.iotop pkgs.lm_sensors pkgs.gitFull pkgs.hwloc
      pkgs.lsof pkgs.numactl pkgs.gcc
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
      build-cores = 0
    '';

  services.zabbixAgent.enable = true;
  services.zabbixAgent.server = "192.168.1.5,127.0.0.1,130.161.158.181";
  services.zabbixAgent.extraConfig =
    ''
      UserParameter=hardware.temp.cpu.average,shopt -s nullglob; cat /sys/devices/platform/coretemp.*/temp1_input /sys/bus/pci/drivers/k10temp/*/temp1_input < /dev/null | ${pkgs.perl}/bin/perl -e 'while (<>) { $n++; $sum += $_; }; print $sum / $n / 1000;'
      UserParameter=vm.memory.dirty,echo $((1024 * $(cat /proc/meminfo | sed 's/Dirty: *\([0-9]\+\) kB/\1/; t; d')))
      UserParameter=vm.memory.ksm.shared,echo -n $((4096 * $(cat /sys/kernel/mm/ksm/pages_shared)))
      UserParameter=vm.memory.ksm.sharing,echo -n $((4096 * $(cat /sys/kernel/mm/ksm/pages_sharing)))
      UserParameter=vm.memory.ksm.unshared,echo -n $((4096 * $(cat /sys/kernel/mm/ksm/pages_unshared)))
      UserParameter=vm.memory.ksm.volatile,echo -n $((4096 * $(cat /sys/kernel/mm/ksm/pages_volatile)))
    '';

  networking.defaultMailServer = {
    directDelivery = true;
    hostName = "smtp.tudelft.nl";
    domain = "st.ewi.tudelft.nl";
  };

  # Bump the open files limit so that non-root users can run NixOS VM
  # tests (Samba opens lot of files).
  security.pam.loginLimits =
    [ { domain = "*"; item = "nofile"; type = "-"; value = "16384"; }
    ];
}
