{ config, pkgs, ... }:

with pkgs.lib;

let
  cfg = config.services.hydra;

  hydraConf = pkgs.writeScript "hydra.conf" 
    ''
      using_frontend_proxy 1
      base_uri ${cfg.hydraURL}
      notification_sender ${cfg.notificationSender}
      max_servers 50
    '';
    
  env = ''NIX_REMOTE=daemon HYDRA_DBI="${cfg.dbi}" HYDRA_CONFIG=${cfg.baseDir}/data/hydra.conf HYDRA_DATA=${cfg.baseDir}/data '';
  server_env = env + ''HYDRA_TRACKER="${cfg.tracker}" '';

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
        default = "dbi:Pg:dbname=hydra;host=webdsl.org;user=hydra;";
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
          Threshold of minimum disk space (G) to determine if queue runner should run or not.  
        '';
      };

      minimumDiskFreeEvaluator = mkOption {
        default = 2;
        description = ''
          Threshold of minimum disk space (G) to determine if evaluator should run or not.  
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
    # $3 / $4 don't always work depending on length of device name
    nix.gc.options = ''--max-freed "$((400 * 1024**3 - 1024 * $(df /nix/store | tail -n 1 | awk '{ print $3 }')))"'';
    
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

    jobs.hydra_init =
      { name = "hydra-init";
        startOn = "started network-interfaces";
        preStart = ''
          mkdir -p ${cfg.baseDir}/data
          chown ${cfg.user} ${cfg.baseDir}/data
          ln -sf ${hydraConf} ${cfg.baseDir}/data/hydra.conf
        '';
        exec = ''
          echo done
        '';
      };

    jobs.hydra_server =
      { name = "hydra-server";
        startOn = "started network-interfaces and started hydra-init";
        exec = ''
          ${pkgs.su}/bin/su - ${cfg.user} -c '${server_env} exec hydra_server.pl -h \* --max_spare_servers 20 --max_servers 50 > ${cfg.baseDir}/data/server.log 2>&1'
        '';
      };

    jobs.hydra_queue_runner =
      { name = "hydra-queue-runner";
        startOn = "started network-interfaces and started hydra-init";
        preStart = "${pkgs.su}/bin/su - ${cfg.user} -c 'hydra_queue_runner.pl --unlock'";
        exec = ''
          ${pkgs.su}/bin/su - ${cfg.user} -c 'exec hydra_queue_runner.pl > ${cfg.baseDir}/data/queue_runner.log 2>&1'
        '';
      };

    jobs.hydra_evaluator =
      { name = "hydra-evaluator";
        startOn = "started network-interfaces";
        exec = ''
          ${pkgs.su}/bin/su - ${cfg.user} -c '${env} exec hydra_evaluator.pl > ${cfg.baseDir}/data/evaluator.log 2>&1'
        '';
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
          compressLogs = pkgs.writeScript "compress-logs" ''
              #! /bin/sh -e
             touch -d 'last month' r
             find /nix/var/log/nix/drvs -type f -a ! -newer r -name '*.drv' | xargs bzip2 -v
           '';
	    in
	    [ "*/5 * * * * root  ${checkSpace} &> ${cfg.baseDir}/data/checkspace.log" 
	      "15 5 * * * root  ${compressLogs} &> ${cfg.baseDir}/data/compress.log"
              "15 02 * * * ${cfg.user} ${env} /home/${cfg.user}/.nix-profile/bin/hydra_update_gc_roots.pl &> ${cfg.baseDir}/data/gc-roots.log"
	    ];

  };  
}

