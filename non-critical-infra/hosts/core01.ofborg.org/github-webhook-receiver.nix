{ config, pkgs, ... }:

{
  systemd.services.ofborg-github-webhook-receiver = {
    description = "ofBorg Webhook Receiver";

    wantedBy = [ "ofborg.target" ];
    bindsTo = [ "ofborg.target" ];
    restartTriggers = [ config.environment.etc."ofborg.json".source ];

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
      ExecStart = "${pkgs.ofborg}/bin/github-webhook-receiver /etc/ofborg.json";
      User = "ofborg-github-webhook-receiver";
      Group = "ofborg-github-webhook-receiver";

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

  services.nginx.virtualHosts."gh-webhook.ofborg.org" = {
    forceSSL = true;
    enableACME = true;

    locations."/".proxyPass = "http://[::1]:9899/";
  };

  users.users.ofborg-github-webhook-receiver = {
    isSystemUser = true;
    group = "ofborg-github-webhook-receiver";
    description = "ofBorg Github webhook receiver system user";
  };
  users.groups.ofborg-github-webhook-receiver = { };

  sops.secrets = {
    "ofborg/github-webhook-secret" = {
      owner = "ofborg-github-webhook-receiver";
      restartUnits = [ "ofborg-github-webhook-receiver.service" ];
      sopsFile = ../../secrets/ofborg.core01.ofborg.org.yml;
    };

    "ofborg/github-webhook-rabbitmq-password" = {
      owner = "ofborg-github-webhook-receiver";
      restartUnits = [ "ofborg-github-webhook-receiver.service" ];
      sopsFile = ../../secrets/ofborg.core01.ofborg.org.yml;
    };
  };
}
