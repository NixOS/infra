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

}
