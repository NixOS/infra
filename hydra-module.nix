{ config, pkgs, ... }:

with pkgs.lib;

let

  cfg = config.services.hydra;

  hydra = "/home/hydra/.nix-profile"; # FIXME

  hydraConf = pkgs.writeScript "hydra.conf"
    ''
      using_frontend_proxy 1
      base_uri ${cfg.hydraURL}
      notification_sender ${cfg.notificationSender}
      max_servers 50
    '';

  env =
    { NIX_REMOTE = "daemon";
      NIX_CONF_DIR = "/etc/nix";
      HYDRA_DBI = cfg.dbi;
      HYDRA_CONFIG = "${cfg.baseDir}/data/hydra.conf";
      HYDRA_DATA = "${cfg.baseDir}/data";
      #HOME = "/home/hydra";
      OPENSSL_X509_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
    };

  serverEnv = env //
    { HYDRA_LOGO = cfg.logo;
      #HYDRA_TRACKER = cfg.tracker; # FIXME: needs escaping (or should be read from a file)
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
        default = "/home/${user.default}";
        description = ''
          The directory holding configuration, logs and temporary files.
        '';
      };

      user = mkOption {
        default = "hydra";
        description = ''
          The user the Hydra services should run as.
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

      tracker = mkOption {
        default = "";
        description = ''
          Piece of HTML that is included on all pages.
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

    users.extraUsers = [
      { name = cfg.user;
        description = "Hydra";
        home = cfg.baseDir;
        createHome = true;
        useDefaultShell = true;
      }
    ];

    nix.maxJobs = 0;
    nix.distributedBuilds = true;
    nix.manualNixMachines = true;
    nix.useChroot = true;
    nix.nrBuildUsers = 100;

    nix.gc.automatic = true;
    nix.gc.options = ''--max-freed "$((400 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | awk '{ print $4 }')))"'';

    nix.extraOptions = ''
      gc-keep-outputs = true
      gc-keep-derivations = true

      # The default (`true') slows Nix down a lot since the build farm
      # has so many GC roots.
      gc-check-reachability = false

      # Hydra needs caching of build failures.
      build-cache-failure = true

      build-poll-interval = 10
    '';

    jobs."hydra-init" =
      { wantedBy = [ "multi-user.target" ];
        script = ''
          mkdir -p ${cfg.baseDir}/data
          chown ${cfg.user} ${cfg.baseDir}/data
          ln -sf ${hydraConf} ${cfg.baseDir}/data/hydra.conf
        '';
        task = true;
      };

    boot.systemd.services."hydra-server" =
      { wantedBy = [ "multi-user.target" ];
        wants = [ "hydra-init.service" ];
        after = [ "hydra-init.service" ];
        environment = serverEnv;
        serviceConfig =
          { ExecStart = "@${hydra}/bin/hydra-server hydra-server -f -h \* --max_spare_servers 5 --max_servers 25 --max_requests 100";
            User = cfg.user;
            Restart = "always";
          };
      };

    boot.systemd.services."hydra-queue-runner" =
      { wantedBy = [ "multi-user.target" ];
        wants = [ "hydra-init.service" ];
        after = [ "hydra-init.service" "network.target" ];
        path = [ pkgs.nettools pkgs.ssmtp ];
        environment = env;
        serviceConfig =
          { ExecStartPre = "${hydra}/bin/hydra-queue-runner --unlock";
            ExecStart = "@${hydra}/bin/hydra-queue-runner hydra-queue-runner";
            User = cfg.user;
            Restart = "always";
          };
      };

    boot.systemd.services."hydra-evaluator" =
      { wantedBy = [ "multi-user.target" ];
        wants = [ "hydra-init.service" ];
        after = [ "hydra-init.service" "network.target" ];
        path = [ pkgs.nettools pkgs.ssmtp ];
        environment = env;
        serviceConfig =
          { ExecStart = "@${hydra}/bin/hydra-evaluator hydra-evaluator";
            User = cfg.user;
            Restart = "always";
          };
      };

    boot.systemd.services."hydra-update-gc-roots" =
      { wants = [ "hydra-init.service" ];
        after = [ "hydra-init.service" ];
        environment = env;
        serviceConfig =
          { ExecStart = "@${hydra}/bin/hydra-update-gc-roots hydra-update-gc-roots";
            User = cfg.user;
          };
      };

    services.cron.systemCronJobs =
      let
        # If there is less than ... GiB of free disk space, stop the queue
        # to prevent builds from failing or aborting.
        checkSpace = pkgs.writeScript "hydra-check-space"
          ''
            #! /bin/sh
            if [ $(($(stat -f -c '%a' /nix/store) * $(stat -f -c '%S' /nix/store))) -lt $((${toString cfg.minimumDiskFree} * 1024**3)) ]; then
                stop hydra-queue-runner
            fi
            if [ $(($(stat -f -c '%a' /nix/store) * $(stat -f -c '%S' /nix/store))) -lt $((${toString cfg.minimumDiskFreeEvaluator} * 1024**3)) ]; then
                stop hydra-evaluator
            fi
          '';
        compressLogs = pkgs.writeScript "compress-logs"
          ''
            #! /bin/sh -e
            touch -d 'last month' r
            find /nix/var/log/nix/drvs -type f -a ! -newer r -name '*.drv' | xargs bzip2 -v
          '';
      in
      [ "*/5 * * * * root ${checkSpace} &> ${cfg.baseDir}/data/checkspace.log"
        "15  5 * * * root ${compressLogs} &> ${cfg.baseDir}/data/compress.log"
        "15  2 * * * root ${pkgs.systemd}/bin/systemctl start hydra-update-gc-roots.service"
      ];

  };
}
