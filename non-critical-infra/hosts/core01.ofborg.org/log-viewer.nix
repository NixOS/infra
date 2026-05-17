{
  config,
  pkgs,
  inputs,
  ...
}:
let
  logviewer = import "${inputs.ofborg-viewer}/release.nix" { inherit pkgs; };
in
{
  systemd.services.ofborg-logapi = {
    description = "ofBorg log api";

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
      ExecStart = "${pkgs.ofborg}/bin/logapi /etc/ofborg.json";
      User = "ofborg-logapi";
      Group = "ofborg-logapi";

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

  users = {
    users.ofborg-logapi = {
      isSystemUser = true;
      group = "ofborg-logapi";
      description = "ofBorg Log Api";
      extraGroups = [ "ofborg-logs" ];
    };
    groups.ofborg-logapi = { };
    users.nginx.extraGroups = [ "ofborg-logs" ];
  };

  services.nginx.virtualHosts."logs.ofborg.org" = {
    forceSSL = true;
    enableACME = true;
    root = "${logviewer}/website";

    locations = {
      "/logfile/" = {
        alias = "/var/log/ofborg/";
        extraConfig = ''
          add_header Access-Control-Allow-Origin "*";
          add_header Access-Control-Request-Method "GET";
          add_header Content-Security-Policy "default-src 'none'; sandbox;";
          add_header Content-Type "text/plain; charset=utf-8";
          add_header X-Content-Type-Options "nosniff";
          add_header X-Frame-Options "deny";
          add_header X-XSS-Protection "1; mode=block";
        '';
      };

      "/logs/" = {
        proxyPass = "http://[::1]:9898";
        extraConfig = ''
          add_header Access-Control-Allow-Origin "*";
          add_header Access-Control-Request-Method "GET";
          add_header Content-Security-Policy "default-src 'none'; sandbox;";
          add_header X-Content-Type-Options "nosniff";
          add_header X-XSS-Protection "1; mode=block";
        '';
      };
    };
  };
}
