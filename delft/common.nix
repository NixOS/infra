{ config, pkgs, ... }:

with pkgs.lib;

{
  imports = [ ./static-net-config.nix ];

  nixpkgs.config.allowUnfree = true;

  users.mutableUsers = false;

  users.extraUsers.root.openssh.authorizedKeys.keys =
     with import ../ssh-keys.nix; [ eelco rob ];

  services.openssh.authorizedKeysFiles = mkForce [ "/etc/ssh/authorized_keys.d/%u" ];

  boot.kernelModules = [ "coretemp" ];

  boot.supportedFilesystems = [ "nfs" ];

  # Prevent "out of sync" errors on the KVM switch.
  boot.vesa = false;
  boot.blacklistedKernelModules = [ "radeonfb" "radeon" "i915" ];

  hardware.enableAllFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  hardware.cpu.intel.updateMicrocode = true;

  environment.systemPackages =
    [ pkgs.emacs pkgs.subversion pkgs.sysstat pkgs.hdparm pkgs.sdparm # pkgs.lsiutil
      pkgs.htop pkgs.sqlite pkgs.iotop pkgs.lm_sensors pkgs.gitFull pkgs.hwloc
      pkgs.lsof pkgs.numactl pkgs.gcc pkgs.smartmontools pkgs.tcpdump pkgs.gdb
    ];

  services.sshd.enable = true;

  boot.kernel.sysctl."kernel.panic" = 60;
  boot.kernel.sysctl."kernel.panic_on_oops" = 1;

  nix.package = pkgs.nixUnstable;

  nix.useChroot = true;

  nix.nrBuildUsers = 100;

  nix.extraOptions =
    ''
      build-cores = 0
      allowed-impure-host-deps = /etc/protocols /etc/services
    '';

  services.zabbixAgent.enable = true;
  services.zabbixAgent.server = "131.180.119.77";
  services.zabbixAgent.extraConfig =
    ''
      UserParameter=hardware.temp.cpu.average,shopt -s nullglob; cat /sys/devices/platform/coretemp.*/temp1_input /sys/bus/pci/drivers/k10temp/*/temp1_input < /dev/null | ${pkgs.perl}/bin/perl -e 'while (<>) { $n++; $sum += $_; }; print $sum / $n / 1000;'
      UserParameter=vm.memory.dirty,echo $((1024 * $(cat /proc/meminfo | sed 's/Dirty: *\([0-9]\+\) kB/\1/; t; d')))
      UserParameter=vm.memory.ksm.shared,echo -n $((4096 * $(cat /sys/kernel/mm/ksm/pages_shared)))
      UserParameter=vm.memory.ksm.sharing,echo -n $((4096 * $(cat /sys/kernel/mm/ksm/pages_sharing)))
      UserParameter=vm.memory.ksm.unshared,echo -n $((4096 * $(cat /sys/kernel/mm/ksm/pages_unshared)))
      UserParameter=vm.memory.ksm.volatile,echo -n $((4096 * $(cat /sys/kernel/mm/ksm/pages_volatile)))
    ''; # */

  networking.defaultMailServer = {
    directDelivery = true;
    hostName = "smtp.tudelft.nl";
    domain = "st.ewi.tudelft.nl";
  };

  networking.extraHosts =
    ''
      104.130.1.245   rackspace-01
      104.130.6.26    rackspace-02
      162.242.229.200 rackspace-03
      162.242.234.29  rackspace-04
      162.242.234.77  rackspace-05
      162.242.234.78  rackspace-06
    '';

  networking.firewall.enable = true;
  networking.firewall.rejectPackets = true;
  networking.firewall.allowPing = true;
  networking.firewall.allowedTCPPorts = [ 10050 ];

  # Bump the open files limit so that non-root users can run NixOS VM
  # tests (Samba opens lot of files).
  security.pam.loginLimits =
    [ { domain = "*"; item = "nofile"; type = "-"; value = "16384"; }
    ];

  # Enable Kernel Samepage Merging (reduces memory footprint of VMs).
  systemd.services."enable-ksm" =
    { description = "Enable Kernel Same-Page Merging";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      script =
        ''
          if [ -e /sys/kernel/mm/ksm ]; then
            echo 1 > /sys/kernel/mm/ksm/run
          fi
        '';
    };

  # Disable the systemd-journald watchdog. The default timeout (1min)
  # can easily be triggered on our slow, heavily-loaded disks. And
  # that may cause services writing to the journal to fail until
  # they're restarted.
  systemd.services.systemd-journald.serviceConfig.WatchdogSec = 0;
}
