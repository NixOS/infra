{ config, pkgs, ... }:

let 

  ZabbixApacheUpdater = pkgs.fetchsvn {
    url = https://www.zulukilo.com/svn/pub/zabbix-apache-stats/trunk/fetch.py ;
    sha256 = "1q66x429wpqjqcmlsi3x37rkn95i55nj8ldzcrblnx6a0jnjgd2g";
    rev = 94;
  };
  
  aselect = import ./aselect {
    inherit (pkgs) stdenv apacheHttpd libtool;
  };
  
  feedback = import ./aselect/feedback.nix {
    inherit (pkgs) stdenv;
  };
in

{
  require = [ ./common.nix ] ;

  boot.initrd.kernelModules = [ "mptsas" ];
  boot.kernelModules = ["acpi-cpufreq" "kvm-intel"];

  nix.maxJobs = 4;

  fileSystems = 
    [ { mountPoint = "/";
        label = "nixos";
      }
      { mountPoint = "/data";
        label = "data";
      }    
    ];

  jobs.aselect = {
    name = "aselect";
    
    startOn = "started httpd";
    
    preStart = ''
      if [ ! -d /var/lib/aselect ]
      then
          mkdir -p /var/lib/aselect/log/aselectagent/system
          cp -a ${aselect}/work /var/lib/aselect
          chmod -R u+rw /var/lib/aselect
          cp ${feedback}/* /var/lib/aselect/work/aselectagent
      fi
    '';
    
    preStop = "${pkgs.jdk}/bin/java -classpath \"${aselect}/bin/aselectagent/\" StopAgent";
    
    exec = "${pkgs.jdk}/bin/java -Duser.dir=\"/var/lib/aselect/work/aselectagent\" -server -jar \"${aselect}/bin/aselectagent/org.aselect.agent.jar\"";
  };

  services.ttyBackgrounds.enable = false; 

  services.zabbixAgent.extraConfig = ''
    UserParameter=mysql_threads,${pkgs.mysql}/bin/mysqladmin -uroot status|cut -f3 -d":"|cut -f1 -d"Q"
    UserParameter=mysql_questions,${pkgs.mysql}/bin/mysqladmin -uroot status|cut -f4 -d":"|cut -f1 -d"S"
    UserParameter=mysql_qps,${pkgs.mysql}/bin/mysqladmin -uroot status|cut -f9 -d":"
    UserParameter=hydra.queue.total,${pkgs.postgresql}/bin/psql hydra -At -c 'select count(*) from builds where finished = 0'
    UserParameter=hydra.queue.building,${pkgs.postgresql}/bin/psql hydra -At -c 'select count(*) from builds natural join BuildSchedulingInfo where finished = 0 and busy = 1'
    UserParameter=hydra.queue.buildsteps,${pkgs.postgresql}/bin/psql hydra -At -c 'select count(*) from BuildSteps s join BuildSchedulingInfo i on s.build = i.id where i.busy = 1 and s.busy = 1'
    UserParameter=hydra.builds,${pkgs.postgresql}/bin/psql hydra -At -c 'select count(*) from Builds'
  '';

  services.systemhealth = {
    enable = true;
    interfaces = [ "lo" "eth0" ];
    drives = [ 
      { name = "root"; path = "/"; } 
      { name = "data"; path = "/data"; } 
    ];
  };

  services.vsftpd = {
    enable = true;
    anonymousUser = true;
  };

  services.sitecopy = {
      enable = true;
      backups =
        let genericBackup = { server = "webdata.tudelft.nl";
                              protocol = "webdav";
                              https = true ;
                            };
        in [
          ( genericBackup // { name = "ftp";   local = "/home/ftp";                          remote = "/staff-groups/ewi/st/strategoxt/backup/ftp/ftp.strategoxt.org/"; } )
          ( genericBackup // { name = "mysql"; local = config.services.mysqlBackup.location; remote = "/staff-groups/ewi/st/strategoxt/backup/mysql"; } )
          ( genericBackup // { name = "tomcat"; local = config.services.tomcat.baseDir;      remote = "/staff-groups/ewi/st/strategoxt/backup/tomcat"; } )
          ( genericBackup // { name   = "postgresql";
                               local  = config.services.postgresqlBackup.location;
                               remote = "/staff-groups/ewi/st/strategoxt/backup/postgresql-webdsl.org";
                             } )
        ];
    };

  services.mysql = {
      enable = true;
      package = pkgs.mysql51;
      dataDir = "/data/mysql";
    };

  services.postgresqlBackup = {
    enable = true;
    databases = [ "hydra" "jira" "mediawiki" ];
  };

  services.syslogd.extraConfig = ''
    local0.*            -/var/log/pgsql
  '';

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
          local all mediawiki        ident mediawiki-users
          local all all              ident sameuser
          host  all all 127.0.0.1/32 md5
          host  all all ::1/128      md5
          host  all all 130.161.159.80/32 md5
          host  all all 130.161.158.181/32 md5
          host  all all 94.208.39.185/32 md5
        ''; 
  };

  services.httpd = rec {
      enable = true;
      adminAddr = "rob.vermaas@gmail.com";

      logPerVirtualHost = true;
      logDir = "/data/www/logs"; 
      logFormat = "combined";

      extraConfig = ''
        <Location /server-status>
                SetHandler server-status
                Allow from 127.0.0.1 # If using a remote host for monitoring replace 127.0.0.1 with its IP.
                Order deny,allow
                Deny from all
        </Location>

        ExtendedStatus On

            <IfModule mod_aselect_filter.c>

            # The location of the error template
            aselect_filter_set_html_error_template "${aselect}/apachefilter/conf/error_template.html"

            # A-Select Agent IP and port
            aselect_filter_set_agent_address "127.0.0.1"
            aselect_filter_set_agent_port "1495"

            # Applications to protect
            aselect_filter_add_secure_app "/evaluaties" "tudfeedb39de56" "default"
            aselect_filter_add_secure_app "/weblab" "tudfeedb39de56" "default"
            # Global options
            aselect_filter_set_use_aselect_bar "0"
            aselect_filter_set_redirect_mode "full"

            # Authorization
            #aselect_filter_add_authz_rule "app1" "*" "ip=127.0.0.1"

            </IfModule>

      '';

      extraSubservices = [
        { serviceType = "tomcat-connector";
          inherit logDir ;
          stateDir = "/var/run/httpd";
          extraWorkersProperties = ''
            worker.list=loadbalancer,loadbalancer2,status
            
            # modify the host as your host IP or DNS name.
            worker.node2.port=8010
            worker.node2.host=localhost
            worker.node2.type=ajp13
            worker.node2.lbfactor=1

            # Load-balancing behaviour
            worker.loadbalancer2.type=lb
            worker.loadbalancer2.balance_workers=node2
          '';
        }
      ];
      
      extraModules = [
        { name = "aselect_filter"; path = "${aselect}/modules/mod_aselect_filter.so"; }
      ];
      
      
      virtualHosts = [
        
        
        { hostName = "webdsl.org";
          extraConfig = ''
JkMount /* loadbalancer
          '';
        }
        
        { hostName = "researchr.org";
          extraConfig = ''
JkMount /* loadbalancer2
          '';
        }
        
        { hostName = "department.st.ewi.tudelft.nl";
          enableSSL = true;
          sslServerCert = "/root/server.crt";
          sslServerKey = "/root/server.key.insecure";
          extraConfig = ''
JkMount /* loadbalancer
          '';
        }
        
        /*{ hostName = "department.st.ewi.tudelft.nl"; }
        
        { hostName = "tweetview.net"; }
        { hostName = "pil-lang.org"; }
        { hostName = "department.st.ewi.tudelft.nl"; }
        { hostName = "phaedrus.webdsl.org"; }
        { hostName = "book.webdsl.org"; }
        { hostName = "yellowgrass.org"; }
        { hostName = "www.yellowgrass.org"; }
        { hostName = "eelcovisser.org"; }
        { hostName = "dsl-engineering.org"; }*/
      ];
    };

  services.xserver.enable = true;
  jobs.tomcat.environment.DISPLAY = ":0.0";
  jobs.tomcat.path = [ pkgs.wkhtmltopdf ];

  services.tomcat = {
      enable = true;
      baseDir = "/data/tomcat";
      javaOpts = "-Dshare.dir=/nix/var/nix/profiles/default/share -Xms350m -Xss8m -Xmx8G -Djava.security.egd=file:/dev/./urandom -XX:MaxPermSize=512M -XX:PermSize=512M -XX:-UseGCOverheadLimit -XX:+UseCompressedOops " 
               + "-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=8999 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Djava.rmi.server.hostname=localhost "
               + "-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/data/tomcat/logs/java_pid<pid>.hprof -Dorg.apache.tomcat.util.http.ServerCookie.ALLOW_EQUALS_IN_VALUE=true";
      logPerVirtualHost = true;
      virtualHosts = [
        { name = "examinr.org";}
        { name = "researchr.org";}
        { name = "webdsl.org"; }
        { name = "tweetview.net"; }
        { name = "pil-lang.org"; }
        { name = "department.st.ewi.tudelft.nl"; }
        { name = "phaedrus.webdsl.org"; }
        { name = "book.webdsl.org"; }
        { name = "yellowgrass.org"; }
        { name = "www.yellowgrass.org"; }
        { name = "eelcovisser.org"; }
        { name = "dsl-engineering.org"; }
      ];
    };

  services.mysqlBackup = {
     enable = true;
     user = "root";
     databases = [ "researchr" "twitterarchive" "webdslorg" "pilweb" "mysql" "yellowgrass" "department" ];
     singleTransaction = true;
     split = true;
     extraArgs = "--ignore-table=researchr._SecurityContext --ignore-table=researchr.RequestLogEntry_params_RequestLogEntryParam --ignore-table=researchr._RequestLogEntry --ignore-table=researchr._RequestLogEntryParam --ignore-table=researchr._RequestLogEntry --ignore-table=researchr._RequestLogEntryParam --ignore-table=researchr.RequestLogEntry_params_RequestLogEntryParam";
   };

  users = {
    extraUsers = let shell = "/var/run/current-system/sw/bin/bash"; in [
      { name = "rbvermaa";
        uid = 1000;
        group = "users";
        extraGroups = [ "wheel" ];
        description = "Rob Vermaas";
        home = "/home/rbvermaa";
        inherit shell;
        createHome = true;
      }
      { name = "zef";
        uid = 1001;
        group = "users";
        extraGroups = [ "wheel" ];
        description = "Zef Hemel";
        home = "/home/zef";
        inherit shell;
        createHome = true;
      }
      { name = "eelcovisser";
        uid = 1002;
        group = "users";
        extraGroups = [ "wheel" ];
        description = "Eelco Visser";
        home = "/home/eelcovisser";
        inherit shell;
        createHome = true;
      }
      { name = "sander";
        uid = 1003;
        group = "users";
        extraGroups = [ "wheel" ];
        description = "Sander van der Burg";
        home = "/home/sander";
        inherit shell;
        createHome = true;
      }
      { name = "danny";
        uid = 1004;
        group = "users";
        extraGroups = [ "wheel" ];
        description = "Danny Groenewegen";
        home = "/home/danny";
        inherit shell;
        createHome = true;
      }
    ];
  }; 


  ######## copied from common ###########

  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.copyKernels = true;
  boot.kernelPackages = pkgs.linuxPackages_2_6_35;

  swapDevices = [ { label = "swap"; } ];

  nix.extraOptions =
    ''
      build-max-silent-time = 3600
    '';

  services.sshd.permitRootLogin = "no";

  services.cron.systemCronJobs =
    [ "15 03 * * * root ${pkgs.nixUnstable}/bin/nix-collect-garbage --max-freed $((32 * 1024**3)) > /var/log/gc.log 2>&1"
      "*  *  * * * root ${pkgs.python}/bin/python ${ZabbixApacheUpdater} -z buildfarm.st.ewi.tudelft.nl -c webdsl"
    ];

  networking = {
    defaultGateway = "130.161.158.1";
    hostName = "webdsl";
    domain = "st.ewi.tudelft.nl";
    extraHosts = "127.0.0.2 webdsl.st.ewi.tudelft.nl webdsl researchr.org department.st.ewi.tudelft.nl "+
                 "webdsl.org tweetview.net pil-lang.org phaedrus.webdsl.org book.webdsl.org "+
                 "yellowgrass.org www.yellowgrass.org eelcovisser.org dsl-engineering.org";

    interfaces = [ { ipAddress = "130.161.159.114"; name = "eth0"; subnetMask = "255.255.254.0"; } ];
    nameservers = [ "130.161.180.1" "130.161.180.65" ];

    useDHCP = false;

    defaultMailServer = {
      directDelivery = true;
      hostName = "smtp.tudelft.nl";
      domain = "st.ewi.tudelft.nl";
    };

  };

  environment.systemPackages = [ pkgs.stdenv /*pkgs.lsiutil*/ ] ++ (with pkgs.strategoPackages018; [ aterm sdf strategoxt ]) ;
}
