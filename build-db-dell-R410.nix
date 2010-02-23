{ config, pkgs, ... }:

{
#  require = [ ./build-machines-common.nix ];
  require = [ ./common.nix ./couchdb.nix ] ;

  boot.initrd.extraKernelModules = ["uhci_hcd" "ehci_hcd" "ata_piix" "mptsas" "usbhid" "ext3"];
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

  environment.extraPackages = [ pkgs.hdparm ];

  services.couchdb = {
    enable = true;
  };

  services.mysql = {
      enable = true;
      dataDir = "/data/mysql";
    };

  services.httpd = rec {
      enable = true;
      adminAddr = "rob.vermaas@gmail.com";

      logPerVirtualHost = true;
      logDir = "/data/www/logs"; 
      logFormat = "combined";

      extraSubservices = [
        { serviceType = "tomcat-connector";
          inherit logDir ;
          stateDir = "/var/run/httpd";
        }
      ];

      extraConfig = ''
        RewriteCond   %{HTTP_HOST}   ^www.researchr.org$   [NC]
        RewriteRule   ^(.*)$   http://researchr.org/$1   [R=301,L]
      '';
    };

  services.tomcat = {
      enable = true;
      baseDir = "/data/tomcat";
      javaOpts = "-Dshare.dir=/nix/var/nix/profiles/default/share -Xms350m -Xmx2048m -XX:MaxPermSize=256M";
      virtualHosts = [
        { name = "researchr.org"; aliases = ["www.researchr.org"] ;}
        { name = "webdsl.org"; }
        { name = "tweetview.net"; }
        { name = "pil-lang.org"; }
      ];
    };

  services.mysqlBackup = {
     enable = true;
     user = "root";
     databases = [ "researchr" "twitterarchive" "webdslorg" "pilweb" ];
   };

  users = {
    extraUsers = [
      { name = "rbvermaa";
        uid = 1000;
        group = "users";
        extraGroups = [ "wheel" ];
        description = "Rob Vermaas";
        home = "/home/rbvermaa";
        shell = pkgs.bash + "/bin/bash";
      }
    ];
  }; 


  ######## copied from common ###########

  boot.grubDevice = "/dev/sda";
  boot.kernelPackages = pkgs.linuxPackages_2_6_29;
  boot.copyKernels = true;

  swapDevices = [ { label = "swap"; } ];

  nix.extraOptions =
    ''
      build-max-silent-time = 3600
    '';

  services.cron.systemCronJobs =
    [ "15 03 * * * root ${pkgs.nixUnstable}/bin/nix-collect-garbage --max-freed $((32 * 1024**3)) > /var/log/gc.log 2>&1"
    ];

  networking = {
    defaultGateway = "130.161.158.1";
    hostName = "webdsl";
    domain = "st.ewi.tudelft.nl";
    extraHosts = "127.0.0.2 webdsl.st.ewi.tudelft.nl webdsl";

    interfaces = [ { ipAddress = "130.161.159.114"; name = "eth0"; subnetMask = "255.255.254.0"; } ];
    nameservers = [ "130.161.158.4" "130.161.158.133" ];

    useDHCP = false;
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
        ];
    };
}
