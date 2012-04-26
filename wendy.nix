{ config, pkgs, ... }:

{
  require = [ ./build-machines-dell-r815.nix ];

  services.httpd.enable = true;
  services.httpd.adminAddr = "e.dolstra@tudelft.nl";
  services.httpd.enableUserDir = true;
  services.httpd.hostName = "wendy";
  services.httpd.extraConfig =
    ''
      UseCanonicalName On
    '';

  jobs.mturk_webserver_production =
    { name = "mturk-webserver-production";
      startOn = "started network-interfaces";
      exec = ''
        ${pkgs.su}/bin/su - mturk -c 'MTURK_STATE=/home/mturk/state-production WEBINTERFACE_HOME=/home/mturk/icse-2012/src/WebInterface WEBINTERFACE_CONFIG=/home/mturk/icse-2012/src/WebInterface/webinterface-production.conf exec /home/mturk/icse-2012/src/WebInterface/script/webinterface_server.pl -f -k >> /home/mturk/state-production/webserver.log 2>&1'
      '';
    };

  jobs.mturk_webserver_sandbox =
    { name = "mturk-webserver-sandbox";
      startOn = "started network-interfaces";
      exec = ''
        ${pkgs.su}/bin/su - mturk -c 'WEBINTERFACE_HOME=/home/mturk/icse-2012/src/WebInterface WEBINTERFACE_CONFIG=/home/mturk/icse-2012/src/WebInterface/webinterface-sandbox.conf exec /home/mturk/icse-2012/src/WebInterface/script/webinterface_server.pl -p 3001 -f -k >> /home/mturk/state-sandbox/webserver.log 2>&1'
      '';
    };

  jobs.mturk_vnc_multiplexer_production =
    { name = "mturk-vnc-multiplexer-production";
      startOn = "started network-interfaces";
      exec = ''
        ${pkgs.su}/bin/su - mturk -c 'MTURK_STATE=/home/mturk/state-production exec vnc-multiplexer.pl >> /home/mturk/state-production/multiplexer.log 2>&1'
      '';
    };

  jobs.mturk_vnc_multiplexer_sandbox =
    { name = "mturk-vnc-multiplexer-sandbox";
      startOn = "started network-interfaces";
      exec = ''
        ${pkgs.su}/bin/su - mturk -c 'exec vnc-multiplexer.pl >> /home/mturk/state-sandbox/multiplexer.log 2>&1'
      '';
    };

  /*
  jobs.mturk_hydra_bridge_production =
    { name = "mturk-hydra-bridge-production";
      exec = ''
        ${pkgs.su}/bin/su - mturk -c 'MTURK_STATE=/home/mturk/state-production exec create-hits-from-hydra.pl >> /home/mturk/state-production/hydra-bridge.log 2>&1'
      '';
    };
  */

  jobs.mturk_vm_cleanup_production =
    { name = "mturk-vm-cleanup-production";
      exec = ''
        ${pkgs.su}/bin/su - mturk -c 'export MTURK_STATE=/home/mturk/state-production; while true; do cleanup-vms.pl >> /home/mturk/state-production/cleanup-vms.log 2>&1; sleep 60; done'
      '';
    };

  services.postgresqlBackup = {
    enable = true;
    databases = [ "hydra" "jira" "mediawiki" ];
  };

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    dataDir = "/data/postgresql";
    extraConfig = ''
      log_min_duration_statement = 1000
      log_duration = off
      log_statement = 'none'
      max_connections = 250
    '';
    authentication = ''
      host  all        all 192.168.1.25/32 md5
      host  hydra      hydra     192.168.1.26/32 md5
      host  hydra_test hydra     192.168.1.26/32 md5
      host  mediawiki  mediawiki 192.168.1.5/32 md5
      host  zabbix     zabbix    192.168.1.5/32 md5
    ''; 
  };

  nixpkgs.config.packageOverrides = pkgs: { postgresql = pkgs.postgresql91; };

  services.zabbixAgent.extraConfig = ''
    UserParameter=hydra.queue.total,${pkgs.postgresql}/bin/psql hydra -At -c 'select count(*) from builds where finished = 0'
    UserParameter=hydra.queue.building,${pkgs.postgresql}/bin/psql hydra -At -c 'select count(*) from builds where finished = 0 and busy = 1'
    UserParameter=hydra.queue.buildsteps,${pkgs.postgresql}/bin/psql hydra -At -c 'select count(*) from BuildSteps s join Builds i on s.build = i.id where i.finished = 0 and i.busy = 1 and s.busy = 1'
    UserParameter=hydra.builds,${pkgs.postgresql}/bin/psql hydra -At -c 'select count(*) from Builds'
  '';

  services.sitecopy = {
      enable = true;
      backups =
        let genericBackup = { server = "webdata.tudelft.nl";
                              protocol = "webdav";
                              https = true ;
                              symlinks = "ignore" ;
                            };
        in [
          ( genericBackup // { name   = "postgresql";
                               local  = config.services.postgresqlBackup.location;
                               remote = "/staff-groups/ewi/st/strategoxt/backup/postgresql-webdsl.org";
                             })
        ];
    };

}
