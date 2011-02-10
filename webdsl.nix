{ config, pkgs, ... }:

let 

  ZabbixApacheUpdater = pkgs.fetchsvn {
    url = https://www.zulukilo.com/svn/pub/zabbix-apache-stats/trunk/fetch.py ;
    sha256 = "1q66x429wpqjqcmlsi3x37rkn95i55nj8ldzcrblnx6a0jnjgd2g";
    rev = 94;
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

  services.ttyBackgrounds.enable = false; 

  services.zabbixAgent.extraConfig = ''
    UserParameter=mysql_threads,${pkgs.mysql}/bin/mysqladmin -uroot status|cut -f3 -d":"|cut -f1 -d"Q"
    UserParameter=mysql_questions,${pkgs.mysql}/bin/mysqladmin -uroot status|cut -f4 -d":"|cut -f1 -d"S"
    UserParameter=mysql_qps,${pkgs.mysql}/bin/mysqladmin -uroot status|cut -f9 -d":"
    UserParameter=hydra.queue.total,${pkgs.postgresql}/bin/psql hydra -At -c 'select count(*) from builds where finished = 0'
    UserParameter=hydra.queue.building,${pkgs.postgresql}/bin/psql hydra -At -c 'select count(*) from builds natural join BuildSchedulingInfo where finished = 0 and busy = 1'
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
      databases = [ "hydra" ];
  };

  services.syslogd.extraConfig = ''
    local0.*		-/var/log/pgsql
  '';

  services.postgresql = {
      enable = true;
      enableTCPIP = true;
      dataDir = "/data/postgresql";
      extraConfig = ''
        log_min_duration_statement = 200
        log_duration = off
        log_statement = 'none'
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
      '';

      extraSubservices = [
        { serviceType = "tomcat-connector";
          inherit logDir ;
          stateDir = "/var/run/httpd";
        }
      ];
    };

  services.tomcat = {
      enable = true;
      baseDir = "/data/tomcat";
      javaOpts = "-Dshare.dir=/nix/var/nix/profiles/default/share -Xms350m -Xss8m -Xmx4096m -XX:MaxPermSize=512M -XX:PermSize=512M -XX:-UseGCOverheadLimit -XX:+UseCompressedOops " 
               + "-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=8999 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Djava.rmi.server.hostname=localhost "
               + "-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/data/tomcat/logs/java_pid<pid>.hprof";
      logPerVirtualHost = true;
      virtualHosts = [
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
    extraHosts = "127.0.0.2 webdsl.st.ewi.tudelft.nl webdsl";

    interfaces = [ { ipAddress = "130.161.159.114"; name = "eth0"; subnetMask = "255.255.254.0"; } ];
    nameservers = [ "130.161.180.65" "130.161.158.4" ];

    useDHCP = false;

    defaultMailServer = {
      directDelivery = true;
      hostName = "smtp.tudelft.nl";
      domain = "st.ewi.tudelft.nl";
    };

  };

  environment.systemPackages = [ pkgs.stdenv pkgs.lsiutil ] ++ (with pkgs.strategoPackages018; [ aterm sdf strategoxt ]) ;
}
