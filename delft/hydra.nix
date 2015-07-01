{ config, pkgs, ... }:

with pkgs.lib;

let

  cfg = config.services.hydra;

  hydra = "/nix/var/nix/profiles/per-user/hydra/profile"; # FIXME

  hydraConf = pkgs.writeScript "hydra.conf"
    ''
      using_frontend_proxy 1
      base_uri ${cfg.hydraURL}
      notification_sender ${cfg.notificationSender}
      max_servers 50
      enable_persona 1

      binary_cache_secret_key_file = /home/hydra-server/.keys/hydra.nixos.org-1/secret

      <hipchat>
        jobs = (hydra|nixops):.*:.*
        room = 182482
        token = ${builtins.readFile ./hipchat-lb-token}
      </hipchat>
    '';

  env =
    { NIX_REMOTE = "daemon";
      NIX_CONF_DIR = "/etc/nix";
      HYDRA_DBI = cfg.dbi;
      HYDRA_CONFIG = hydraConf;
      HYDRA_DATA = cfg.baseDir;
      SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    };

  serverEnv = env //
    { HYDRA_LOGO = cfg.logo;
      HYDRA_SERVER_DATA = "/var/lib/hydra-server";
      COLUMNS = "80";
    };

in

{
  ###### interface

  options = {

    services.hydra = rec {

      enable = mkOption {
        default = false;
        description = ''
          Whether to run Hydra services.
        '';
      };

      baseDir = mkOption {
        default = "/var/lib/hydra";
        description = ''
          The directory holding configuration, logs and temporary files.
        '';
      };

      dbi = mkOption {
        default = "dbi:Pg:dbname=hydra;host=wendy;user=hydra;";
        description = ''
          The DBI string for Hydra database connection
        '';
      };

      hydraURL = mkOption {
        default = "http://hydra.nixos.org";
        description = ''
          The base URL for the Hydra webserver instance. Used for links in emails.
        '';
      };

      minimumDiskFree = mkOption {
        default = 5;
        description = ''
          Threshold of minimum disk space (GiB) to determine if queue runner should run or not.
        '';
      };

      minimumDiskFreeEvaluator = mkOption {
        default = 2;
        description = ''
          Threshold of minimum disk space (GiB) to determine if evaluator should run or not.
        '';
      };

      notificationSender = mkOption {
        default = "e.dolstra@tudelft.nl";
        description = ''
          Sender email address used for email notifications.
        '';
      };

      logo = mkOption {
        default = "";
        description = ''
          Path to a file containing the logo of your Hydra instance.
        '';
      };

    };

  };


  ###### implementation

  config = mkIf cfg.enable {

    users.extraUsers.hydra =
      { description = "Hydra";
        group = "hydra";
        createHome = true;
        home = "/home/hydra";
        useDefaultShell = true;
      };

    users.extraUsers.hydra-server =
      { description = "Hydra Web Server";
        group = "hydra";
        createHome = true;
        home = "/home/hydra-server";
        useDefaultShell = true;
      };

    users.extraGroups.hydra = { };

    nix.maxJobs = 0;
    nix.distributedBuilds = true;

    nix.gc.automatic = true;
    nix.gc.options = ''--max-freed "$((700 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';

    nix.extraOptions = ''
      gc-keep-outputs = true
      gc-keep-derivations = true

      # The default (`true') slows Nix down a lot since the build farm
      # has so many GC roots.
      gc-check-reachability = false

      # Hydra needs caching of build failures.
      build-cache-failure = true

      build-poll-interval = 10

      # Online log compression makes it impossible to get the tail of
      # builds that are in progress.
      build-compress-log = false
    '';

    jobs.hydra-init =
      { wantedBy = [ "multi-user.target" ];
        script = ''
          mkdir -m 0750 -p ${cfg.baseDir}
          chown hydra.hydra ${cfg.baseDir}
        '';
        task = true;
      };

    systemd.services.hydra-server =
      { wantedBy = [ "multi-user.target" ];
        wants = [ "hydra-init.service" ];
        after = [ "hydra-init.service" ];
        environment = serverEnv;
        preStart =
          ''
            mkdir -m 0700 -p /var/lib/hydra-server
            chown hydra-server.hydra /var/lib/hydra-server
          '';
        serviceConfig =
          { ExecStart = "@${hydra}/bin/hydra-server hydra-server -f -h \* --max_spare_servers 5 --max_servers 25 --max_requests 100";
            User = "hydra-server";
            PermissionsStartOnly = true;
            Restart = "always";
          };
      };

    systemd.services.hydra-queue-runner =
      { #wantedBy = [ "multi-user.target" ];
        wants = [ "hydra-init.service" ];
        after = [ "hydra-init.service" "network.target" ];
        path = [ pkgs.nettools pkgs.ssmtp ];
        environment = env;
        serviceConfig =
          { ExecStartPre = "${hydra}/bin/hydra-queue-runner --unlock";
            ExecStart = "@${hydra}/bin/hydra-queue-runner hydra-queue-runner";
            ExecStopPost = "${hydra}/bin/hydra-queue-runner --unlock";
            User = "hydra";
            Restart = "always";
          };
      };

    systemd.services.hydra-evaluator =
      { wantedBy = [ "multi-user.target" ];
        wants = [ "hydra-init.service" ];
        after = [ "hydra-init.service" "network.target" ];
        path = [ pkgs.nettools pkgs.ssmtp ];
        environment = env;
        serviceConfig =
          { ExecStart = "@${hydra}/bin/hydra-evaluator hydra-evaluator";
            User = "hydra";
            Restart = "always";
          };
      };

    systemd.services.hydra-update-gc-roots =
      { wants = [ "hydra-init.service" ];
        after = [ "hydra-init.service" ];
        environment = env;
        serviceConfig =
          { ExecStart = "@${hydra}/bin/hydra-update-gc-roots hydra-update-gc-roots";
            User = "hydra";
          };
        startAt = "2,14:15";
      };

    # If there is less than ... GiB of free disk space, stop the queue
    # to prevent builds from failing or aborting.
    systemd.services.hydra-check-space =
      { script =
          ''
            if [ $(($(stat -f -c '%a' /nix/store) * $(stat -f -c '%S' /nix/store))) -lt $((${toString cfg.minimumDiskFree} * 1024**3)) ]; then
                systemctl stop hydra-queue-runner
            fi
            if [ $(($(stat -f -c '%a' /nix/store) * $(stat -f -c '%S' /nix/store))) -lt $((${toString cfg.minimumDiskFreeEvaluator} * 1024**3)) ]; then
                systemctl stop hydra-evaluator
            fi
          '';
        startAt = "*:0/5";
      };

  };
}
