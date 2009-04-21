let 

  pkgs = import /etc/nixos/nixpkgs {};

  machines = import ./machines.nix;

  machineList = map (name: {hostName = name;} // builtins.getAttr name machines)
    (builtins.attrNames machines);

  # Produce the list of Nix build machines in the format expected by
  # the Nix daemon Upstart job.
  buildMachines =
    let addKey = machine: machine // 
      { sshKey = "/root/.ssh/id_buildfarm";
        sshUser = machine.buildUser;
      };
    in map addKey (pkgs.lib.filter (machine: machine ? buildUser) machineList);

  supervisor = import ../../release/supervisor/supervisor.nix {
    stateDir = "/home/buildfarm/buildfarm-state";
    jobsFile = toString /home/buildfarm/jobs.nix;
    fromAddress = "TU Delft Nix Buildfarm <e.dolstra@tudelft.nl>";
  };

  jiraJetty = (import ../../services/jira/jira-instance.nix).jetty;

  myIP = "130.161.158.181";

  releasesCSS = /etc/nixos/release/generic-dist/release-page/releases.css;

in

rec {

  boot = {
    grubDevice = "/dev/sda";
    initrd = {
      extraKernelModules = ["arcmsr"];
    };
    kernelModules = ["kvm-intel"];
    kernelPackages = pkgs: pkgs.kernelPackages_2_6_27;
  };

  fileSystems = [
    { mountPoint = "/";
      label = "nixos";
      options = "acl,noatime";
    }
  ];

  swapDevices = [
    { label = "swap1"; }
  ];
  
  nix = {
    maxJobs = 0;
    distributedBuilds = true;
    inherit buildMachines;
    extraOptions = ''
      gc-keep-outputs = true
      
      # The default (`true') slows Nix down a lot since the build farm
      # has so many GC roots.
      gc-check-reachability = false

      # Hydra needs caching of build failures.
      build-cache-failure = true

      build-poll-interval = 10
    '';
  };
  
  networking = {
    hostName = "cartman";
    domain = "buildfarm";

    interfaces = [
      { name = "eth1";
        ipAddress = myIP;
        subnetMask = "255.255.254.0";
      }
      { name = "eth0";
        ipAddress = machines.cartman.ipAddress;
      }
    ];

    defaultGateway = "130.161.158.1";

    nameservers = ["130.161.158.4" "130.161.33.17" "130.161.180.1"];

    extraHosts = 
      let toHosts = m: "${m.ipAddress} ${m.hostName} ${pkgs.lib.concatStringsSep " " (if m ? aliases then m.aliases else [])}\n"; in
      pkgs.lib.concatStrings (map toHosts machineList);

    localCommands =
      # Provide NATting for the build machines on 192.168.1.*.
      # Obviously, this should be something that NixOS provides.
      ''
        export PATH=${pkgs.iptables}/sbin:$PATH

        modprobe ip_tables
        modprobe ip_conntrack_ftp
        modprobe ip_nat_ftp
        modprobe ipt_LOG
        modprobe ip_nat
        modprobe xt_tcpudp

        iptables -t nat -F
        iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -d 192.168.1.0/24 -j ACCEPT
        iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -j SNAT --to-source ${myIP}

        echo 1 > /proc/sys/net/ipv4/ip_forward
      '';

    defaultMailServer = {
      directDelivery = true;
      hostName = "smtp.st.ewi.tudelft.nl";
      domain = "st.ewi.tudelft.nl";
    };
  };

  services = {
    sshd = {
      enable = true;
    };

    cron = {
      systemCronJobs =
        let indexJob = hour: dir: url: 
          "45 ${toString hour} * * *  buildfarm  (cd /etc/nixos/release/index && PATH=${pkgs.saxonb}/bin:$PATH ./make-index.sh ${dir} ${url} /releases.css) | ${pkgs.utillinux}/bin/logger -t index";
        in
        [
          "15 0 * * *  root  (TZ=CET date; ${pkgs.rsync}/bin/rsync -razv --numeric-ids --delete /data/subversion* /data/vm /data/pt-wiki /data/postgresql /data/webserver/tarballs /home/buildfarm/hydra unixhome.st.ewi.tudelft.nl::bfarm/) >> /var/log/backup.log 2>&1"

          # Releases indices.
          (indexJob 01 "/data/webserver/dist/nix" http://nixos.org/releases/)
          (indexJob 02 "/data/webserver/dist/strategoxt2" http://releases.strategoxt.org/)
          (indexJob 05 "/data/webserver/dist" http://buildfarm.st.ewi.tudelft.nl/)

          "00 03 * * * root ${pkgs.nixUnstable}/bin/nix-collect-garbage --max-atime $(date +\\%s -d '2 weeks ago') > /var/log/gc.log 2>&1"
        ];
    };

    dhcpd = {
      enable = true;
      interfaces = ["eth0"];
      extraConfig = ''
        option subnet-mask 255.255.255.0;
        option broadcast-address 192.168.1.255;
        option routers 192.168.1.5;
        option domain-name-servers 130.161.158.4, 130.161.33.17, 130.161.180.1;
        option domain-name "buildfarm-net";

        subnet 192.168.1.0 netmask 255.255.255.0 {
          range 192.168.1.100 192.168.1.200;
        }

        use-host-decl-names on;
      '';
      machines = pkgs.lib.filter (machine: machine ? ethernetAddress) machineList;
    };
    
    extraJobs = [

      { name = "buildfarm";
        extraPath = [supervisor];
        job = ''
          description "Build farm job runner"

          start on network-interfaces/started
          stop on network-interfaces/stop

          respawn ${pkgs.su}/bin/su - buildfarm -c 'sendNotifications=1 ${supervisor}/bin/buildfarm-supervisor' > /var/log/buildfarm 2>&1
        '';
      }

      { name = "jira";
        users = [
          { name = "jira";
            description = "JIRA bug tracker";
          }
        ];
        job = ''
          description "JIRA bug tracker"

          start on network-interfaces/started
          stop on network-interfaces/stop

          start script
              mkdir -p /var/log/jetty /var/cache/jira
              chown jira /var/log/jetty /var/cache/jira
          end script

          respawn ${pkgs.su}/bin/su -s ${pkgs.bash}/bin/sh jira -c '${jiraJetty}/bin/run-jetty'
          
          stop script
              ${pkgs.su}/bin/su -s ${pkgs.bash}/bin/sh jira -c '${jiraJetty}/bin/stop-jetty'
          end script
        '';
      }

    ];

    postgresql = {
      enable = true;
      dataDir = "/data/postgresql";
    };

    httpd = {
      enable = true;
      experimental = true;
      logPerVirtualHost = true;
      adminAddr = "e.dolstra@tudelft.nl";
      hostName = "localhost";

      sslServerCert = "/root/ssl-secrets/server.crt";
      sslServerKey = "/root/ssl-secrets/server.key";
          
      extraConfig = ''
        AddType application/nix-package .nixpkg

        ScriptAlias /status /home/eelco/release/status/status.pl
        <Location /status>
          Order deny,allow
          Allow from all
        </Location>
      '';
          
      servedFiles = [
        { urlPath = "/releases.css";
          file = releasesCSS;
        }
        { urlPath = "/css/releases.css"; # legacy; old releases point here
          file = releasesCSS;
        }
        { urlPath = "/releases/css/releases.css"; # legacy; old releases point here
          file = releasesCSS;
        }
      ];
      
      virtualHosts = [

        { hostName = "buildfarm.st.ewi.tudelft.nl";
          documentRoot = pkgs.lib.cleanSource ./webroot;
          enableUserDir = true;
          extraSubservices = [
            { serviceType = "subversion";
              urlPrefix = "";
              toplevelRedirect = false;
              dataDir = "/data/subversion";
              notificationSender = "svn@buildfarm.st.ewi.tudelft.nl";
              userCreationDomain = "st.ewi.tudelft.nl";
              organisation = {
                name = "Software Engineering Research Group, TU Delft";
                url = http://www.st.ewi.tudelft.nl/;
                logo = "/serg-logo.png";
              };
            }
            { serviceType = "subversion";
              id = "ptg";
              urlPrefix = "/ptg";
              dataDir = "/data/subversion-ptg";
              notificationSender = "svn@buildfarm.st.ewi.tudelft.nl";
              userCreationDomain = "st.ewi.tudelft.nl";
              organisation = {
                name = "Software Engineering Research Group, TU Delft";
                url = http://www.st.ewi.tudelft.nl/;
                logo = "/serg-logo.png";
              };
            }
            { serviceType = "zabbix";
              urlPrefix = "/zabbix";
            }
          ];
          servedDirs = [
            { urlPath = "/releases";
              dir = "/data/webserver/dist";
            }
          ];
        }

        # Default vhost for SSL; nothing here yet, but we need it,
        # otherwise SSL requests that don't match with any vhost will
        # go to svn.strategoxt.org.
        { hostName = "buildfarm.st.ewi.tudelft.nl";
          enableSSL = true;
          globalRedirect = "http://buildfarm.st.ewi.tudelft.nl/";
        }
        
        { hostName = "strategoxt.org";
          extraSubservices = [
            { serviceType = "twiki";
              startWeb = "Stratego/WebHome";
            }
          ];
        }

        { hostName = "www.strategoxt.org";
          serverAliases = ["www.stratego-language.org"];
          globalRedirect = "http://strategoxt.org/";
        }

        { hostName = "svn.strategoxt.org";
          globalRedirect = "https://svn.strategoxt.org/";
        }
        
        { hostName = "svn.strategoxt.org";
          enableSSL = true;
          extraSubservices = [
            { serviceType = "subversion";
              id = "strategoxt";
              urlPrefix = "";
              dataDir = "/data/subversion-strategoxt";
              notificationSender = "svn@svn.strategoxt.org";
              userCreationDomain = "st.ewi.tudelft.nl";
              organisation = {
                name = "Stratego/XT";
                url = http://strategoxt.org/;
                logo = http://strategoxt.org/pub/Stratego/StrategoLogo/StrategoLogoTextlessWhite-100px.png;
              };
            }
          ];
        }

        { hostName = "program-transformation.org";
          serverAliases = ["www.program-transformation.org"];
          extraSubservices = [
            { serviceType = "twiki";
              startWeb = "Transform/WebHome";
            }
          ];
        }

        { hostName = "bugs.strategoxt.org";
          extraConfig = ''
            <Proxy *>
              Order deny,allow
              Allow from all
            </Proxy>

            ProxyRequests     Off
            ProxyPreserveHost On
            ProxyPass         /       http://localhost:10080/
            ProxyPassReverse  /       http://localhost:10080/
          '';
        }

        { hostName = "releases.strategoxt.org";
          documentRoot = "/data/webserver/dist/strategoxt2";
        }

        { hostName = "nixos.org";
          documentRoot = "/home/eelco/nix-homepage";
          servedDirs = [
            { urlPath = "/releases";
              dir = "/data/webserver/dist/nix";
            }
            { urlPath = "/tarballs";
              dir = "/data/webserver/tarballs";
            }
          ];
          servedFiles = [
            { urlPath = "/releases/css/releases.css";
              file = releasesCSS;
            }
          ];
        }

        { hostName = "www.nixos.org";
          globalRedirect = "http://nixos.org/";
        }
        
        { hostName = "svn.nixos.org";
          enableSSL = true;
          extraSubservices = [
            { serviceType = "subversion";
              id = "nix";
              urlPrefix = "";
              dataDir = "/data/subversion-nix";
              notificationSender = "svn@svn.nixos.org";
              userCreationDomain = "st.ewi.tudelft.nl";
              organisation = {
                name = "Nix";
                url = http://nixos.org/;
                logo = http://subversion.tigris.org/images/subversion_logo_hor-468x64.png; # !!! need a logo
              };
            }
          ];
        }

        { hostName = "svn.nixos.org";
          globalRedirect = "https://svn.nixos.org/";
        }
        
        { hostName = "hydra.nixos.org";
          extraConfig = ''
            <Proxy *>
              Order deny,allow
              Allow from all
            </Proxy>

            ProxyRequests     Off
            ProxyPreserveHost On
            ProxyPass         /       http://hydra:3000/
            ProxyPassReverse  /       http://hydra:3000/
          '';
        }

        { hostName = "planet.strategoxt.org";
          serverAliases = ["planet.stratego.org"];
          documentRoot = "/home/karltk/public_html/planet";
        }

      ];
    };

    zabbixAgent = {
      enable = true;
    };

    zabbixServer = {
      enable = true;
    };

  };

}
