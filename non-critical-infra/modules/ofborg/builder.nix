{ config, pkgs, ... }:

{
  imports = [
    ./common.nix
    ./ofborg-config.nix
    ./harmonia.nix
  ];

  networking.extraHosts = ''
    95.216.209.162 eval02.ofborg.org
    37.27.189.4 eval03.ofborg.org
    95.217.18.12 eval04.ofborg.org

    185.119.168.10 build01.ofborg.org
    185.119.168.11 build02.ofborg.org
    185.119.168.12 build03.ofborg.org
    185.119.168.13 build04.ofborg.org
    142.132.171.106 build05.ofborg.org
  '';

  deployment.tags = [ "ofborg-builder" ];

  systemd.services.ofborg-builder = {
    description = "ofBorg builder";

    wantedBy = [ "ofborg.target" ];
    bindsTo = [ "ofborg.target" ];
    restartTriggers = [ config.environment.etc."ofborg.json".source ];

    path = [
      config.nix.package
      config.programs.git.package
    ];

    environment = {
      GIT_AUTHOR_NAME = "OfBorg";
      GIT_COMMITTER_NAME = "OfBorg";
      EMAIL = "ofborg@nixos.org";
    };

    stopIfChanged = false;
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig = {
      # Filesystem stuff
      ProtectSystem = "strict"; # Prevent writing to most of /
      ProtectHome = true; # Prevent accessing /home and /root
      PrivateTmp = true; # Give an own directory under /tmp
      PrivateDevices = true; # Deny access to most of /dev
      ProtectKernelTunables = true; # Protect some parts of /sys
      ProtectControlGroups = true; # Remount cgroups read-only
      RestrictSUIDSGID = true; # Prevent creating SETUID/SETGID files
      PrivateMounts = true; # Give an own mount namespace
      RemoveIPC = true;
      UMask = "0077";

      Restart = "always";
      RestartSec = "5s";
      ExecStart = "${pkgs.ofborg}/bin/builder /etc/ofborg.json";
      User = "ofborg-builder";
      Group = "ofborg-builder";

      StateDirectory = [ "ofborg/checkout" ];

      # Capabilities
      CapabilityBoundingSet = ""; # Allow no capabilities at all
      NoNewPrivileges = true; # Disallow getting more capabilities. This is also implied by other options.

      # Kernel stuff
      ProtectKernelModules = true; # Prevent loading of kernel modules
      SystemCallArchitectures = "native"; # Usually no need to disable this
      ProtectKernelLogs = true; # Prevent access to kernel logs
      ProtectClock = true; # Prevent setting the RTC

      # Misc
      LockPersonality = true; # Prevent change of the personality
      ProtectHostname = true; # Give an own UTS namespace
      RestrictRealtime = true; # Prevent switching to RT scheduling
      MemoryDenyWriteExecute = true; # Maybe disable this for interpreters like python
      PrivateUsers = true; # If anything randomly breaks, it's mostly because of this
      RestrictNamespaces = true;
      SystemCallFilter = "@system-service";
    };
  };

  users.users.ofborg-builder = {
    isSystemUser = true;
    group = "ofborg-builder";
    description = "ofBorg builder system user";
  };
  users.groups.ofborg-builder = { };
}
