{ config, pkgs, lib, ... }:

with lib;

{
  imports =
    [ ./diffoscope.nix
      ../modules/common.nix
      ../modules/prometheus
      ../modules/wireguard.nix
      ../modules/prometheus
    ];

  system.stateVersion = "14.12";

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (self: super: {
      prometheus-postgres-exporter = self.callPackage ./prometheus/postgres-exporter.nix { };
    })
  ];

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

  nix.nrBuildUsers = 100;

  nix.extraOptions =
    ''
      allowed-impure-host-deps = /etc/protocols /etc/services /etc/nsswitch.conf
      allowed-uris = https://github.com/ https://git.savannah.gnu.org/ github:
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

  environment.enableDebugInfo = true;

  systemd.tmpfiles.rules = [ "d /tmp 1777 root root 7d" ];

  # Disable sending email from cron.
  services.cron.mailto = "";

  documentation.nixos.enable = false;

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "webmaster@nixos.org";
}
