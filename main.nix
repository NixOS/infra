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

    interfaces = [
      { name = "eth1";
        ipAddress = "130.161.158.181";
        subnetMask = "255.255.254.0";
      }
      { name = "eth0";
        ipAddress = "192.168.1.5";
      }
    ];

    defaultGateway = "130.161.158.1";

    nameservers = ["130.161.158.4" "130.161.33.17" "130.161.180.1"];

    localCommands =
      # Provide NATting for the build machines on 192.168.1.*.
      # Obviously, this should be something that NixOS provides.
      let pkgs = import ../../nixpkgs/pkgs/top-level/all-packages.nix {};
      in "
        export PATH=${pkgs.iptables}/sbin:$PATH

        modprobe ip_tables
        modprobe ip_conntrack_ftp
        modprobe ip_nat_ftp
        modprobe ipt_LOG
        modprobe ip_nat
        modprobe xt_tcpudp

        iptables -t nat -F
        iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -d 192.168.1.0/24 -j ACCEPT
        iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -j SNAT --to-source 130.161.158.181

        echo 1 > /proc/sys/net/ipv4/ip_forward
      ";
  };

  services = {
    sshd = {
      enable = true;
    };

    dhcpd = {
      enable = true;
      configFile = ./dhcpd.conf;
      interfaces = ["eth0"];
    };
    
    httpd = {
      enable = true;
      adminAddr = "eelco@cs.uu.nl";
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
