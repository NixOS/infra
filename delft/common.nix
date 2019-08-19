{ config, pkgs, lib, ... }:

with lib;

{
  imports =
    [ ./static-net-config.nix
      ./diffoscope.nix
      # broke due to flakes, and then pinned back
      ((builtins.fetchGit {
        url = https://github.com/edolstra/dwarffs.git;
      rev = "531a2338101f0b6db2d9d512c3f98145f7b75397";
       }) + "/module.nix")
      ../modules/common.nix
      ./prometheus/node.nix
    ];

  system.stateVersion = "14.12";

  nixpkgs.config.allowUnfree = true;

  services.openssh.authorizedKeysFiles = mkForce [ "/etc/ssh/authorized_keys.d/%u" ];

  services.openssh.extraConfig =
    ''
      PubkeyAcceptedKeyTypes +ssh-dss
    '';

  boot.kernelModules = [ "coretemp" ];

  # Prevent "out of sync" errors on the KVM switch.
  boot.vesa = false;
  boot.blacklistedKernelModules = [ "radeonfb" "radeon" "i915" ];
  boot.kernelParams = [ "nomodeset" ];

  hardware.enableAllFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  hardware.cpu.intel.updateMicrocode = true;

  environment.systemPackages =
    [ pkgs.emacs pkgs.sysstat pkgs.hdparm pkgs.sdparm # pkgs.lsiutil
      pkgs.htop pkgs.sqlite pkgs.iotop pkgs.lm_sensors pkgs.hwloc
      pkgs.lsof pkgs.numactl pkgs.gcc pkgs.smartmontools pkgs.tcpdump pkgs.gdb
      pkgs.elfutils
    ];

  services.sshd.enable = true;

  boot.kernel.sysctl."kernel.panic" = 60;
  boot.kernel.sysctl."kernel.panic_on_oops" = 1;

  nix.package = pkgs.nixFlakes;

  nix.nrBuildUsers = 100;

  nix.extraOptions =
    ''
      allowed-impure-host-deps = /etc/protocols /etc/services /etc/nsswitch.conf
    '';

  networking.defaultMailServer = {
    directDelivery = true;
    hostName = "smtp.tudelft.nl";
    domain = "st.ewi.tudelft.nl";
  };

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

  environment.enableDebugInfo = true;

  systemd.tmpfiles.rules = [ "d /tmp 1777 root root 7d" ];

  # Disable sending email from cron.
  services.cron.mailto = "";
}
