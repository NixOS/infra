rec {
  boot = {
    grubDevice = "/dev/sda";
    initrd = {
      extraKernelModules = ["arcmsr"];
    };
    extraKernelModules = ["kvm-intel"];
  };

  fileSystems = [
    { mountPoint = "/";
      label = "nixos";
    }
  ];

  swapDevices = [
    { label = "swap1"; }
  ];
  
  nix = {
    maxJobs = 2;
  };
  
  networking = {
    hostName = "buildfarm";
    defaultGateway = "130.161.158.1";

    interfaces = [
      { name = "eth1";
        ipAddress = "130.161.158.181";
        subnetMask = "255.255.254.0";
      }
      { name = "eth0";
        ipAddress = "192.168.1.5";
      }
    ];
  };

  services = {
    sshd = {
      enable = true;
    };
    
    httpd = {
      enable = true;
      adminAddr = "admin@example.org";
      hostName = "buildfarm.st.ewi.tudelft.nl";

      subservices = {
        subversion = {
          enable = true;
          dataDir = "/data/subversion";
          notificationSender = "svn@example.org";
          userCreationDomain = "st.ewi.tudelft.nl";
          
          organization = {
            name = "Software Engineering Research Group, TU Delft";
            url  = "http://swerl.tudelft.nl";
            logo = ./serg-logo.png;
          };
        };
      };

      extraSubservices = {
        enable = true;
        services = [distManagerService rootFiles];
      };
    };
  };

  distManagerService = webServer : pkgs :
    (distManager webServer pkgs) {
      distDir = "/data/webserver/dist";
      distPrefix = "/releases";
      distConfDir = "/data/webserver/dist-conf";
      directories = ./dist-manager/directories.conf;
    };

  distManager = webServer : pkgs : { distDir, distPrefix, distConfDir, directories} :
    import ../../services/dist-manager {
      inherit (pkgs) stdenv perl;
      saxon8 = pkgs.saxonb;
      inherit distDir distPrefix distConfDir directories;
      canonicalName = "http://" + webServer.hostName + 
        (if webServer.httpPort == 80 then "" else ":" + (toString webServer.httpPort));
    };

  rootFiles =  webServer : pkgs :
    import ../../services/apache-httpd/subservices/serve-files {
      directory = ./webroot;
      urlPath = "/";
      inherit (pkgs) stdenv;
    };
}
