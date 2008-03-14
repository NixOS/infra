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
    #jobsURL = https://svn.cs.uu.nl:12443/repos/trace/configurations/trunk/tud/supervisor/jobs.nix;
    jobsFile = toString /etc/nixos/configurations/tud/supervisor/jobs.nix;
    smtpHost = "smtp.st.ewi.tudelft.nl";
    fromAddress = "TU Delft Nix Buildfarm <martin@st.ewi.tudelft.nl>";
  };

  supervisorOld = import ../../old-release/supervisor/supervisor.nix {
    stateDir = "/home/buildfarm/buildfarm-state-old";
    jobsURL = https://svn.cs.uu.nl:12443/repos/trace/configurations/trunk/tud/supervisor/jobs.conf;
    smtpHost = "smtp.st.ewi.tudelft.nl";
    fromAddress = "TU Delft Nix Legacy Buildfarm <martin@st.ewi.tudelft.nl>";
  };

  jiraJetty = (import ../../services/jira/jira-instance.nix).jetty;

  myIP = "130.161.158.181";

in

rec {

  boot = {
    grubDevice = "/dev/sda";
    initrd = {
      extraKernelModules = ["arcmsr"];
    };
    kernelModules = ["kvm-intel"];
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
    distributedBuilds = true;
    inherit buildMachines;
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
      let toHosts = m: "${m.ipAddress} ${m.hostName} ${pkgs.lib.concatStringsSep " " m.aliases}\n"; in
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
      systemCronJobs = [
        "25 * * * *  root  (TZ=CET date; ${pkgs.rsync}/bin/rsync -razv --numeric-ids --delete /data/subversion /data/subversion-strategoxt /data/subversion-nix /data/vm /data/pt-wiki /data/postgresql unixhome.st.ewi.tudelft.nl::bfarm/) >> /var/log/backup.log 2>&1"
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

      { name = "buildfarm-supervisor";
        job = ''
          description "Build farm job starter"

          start on network-interfaces/started
          stop on network-interfaces/stop

          respawn ${pkgs.su}/bin/su - buildfarm -c ${supervisor}/bin/run > /var/log/buildfarm 2>&1
        '';
      }

      { name = "buildfarm-supervisor-old";
        job = ''
          description "Build farm job starter (legacy jobs)"

          start on network-interfaces/started
          stop on network-interfaces/stop

          respawn ${pkgs.su}/bin/su - buildfarm -c ${supervisorOld}/bin/run > /var/log/buildfarm-old 2>&1
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

    nagios = {
      enable = true;
      enableWebInterface = true;
      objectDefs = [
        ./nagios-base.cfg
        (pkgs.writeText "nagios-machines.cfg" (
          map (machine:
            let hostName = machine.hostName; in
            "
              define host {
                host_name  ${hostName}
                use        generic-server
                alias      Build machine ${hostName} (${machine.system})
                address    ${hostName}
                hostgroups tud-buildfarm
              }

              define service {
                service_description SSH on ${hostName}
                use                 local-service
                host_name           ${hostName}
                servicegroups       ssh
                check_command       check_ssh
              }

              #define service {
              #  service_description /nix on ${hostName}
              #  use                 local-service
              #  host_name           ${hostName}
              #  servicegroups       diskspace
              #  check_command       check_remote_disk!nagios!/var/lib/nagios/id_nagios!75%!10%!/nix
              #}
            "
          ) machineList
        ))
      ];
    };
    
    httpd = {
      enable = true;
      experimental = true;
      logPerVirtualHost = true;
      adminAddr = "eelco@cs.uu.nl";
      hostName = "localhost";

      virtualHosts = [

        { hostName = "buildfarm.st.ewi.tudelft.nl";
          documentRoot = pkgs.lib.cleanSource ./webroot;
          extraSubservices = [
            { function = import /etc/nixos/nixos/upstart-jobs/apache-httpd/subversion.nix;
              config = {
                urlPrefix = "";
                toplevelRedirect = false;
                dataDir = "/data/subversion";
                notificationSender = "root@buildfarm.st.ewi.tudelft.nl";
                userCreationDomain = "st.ewi.tudelft.nl";
                organisation = {
                  name = "Software Engineering Research Group, TU Delft";
                  url = http://www.st.ewi.tudelft.nl/;
                  logo = "/serg-logo.png";
                };
              };
            }
            { function = import /etc/nixos/nixos/upstart-jobs/apache-httpd/dist-manager.nix;
              config = rec {
                urlPrefix = "/releases";
                distDir = "/data/webserver/dist";
                uploaderIPs = ["127.0.0.1" myIP];
                distPasswords = "/data/webserver/upload_passwords";
                directoriesConf = ''
                  nix          ${distDir}/nix          nix-upload
                  nix-cache    ${distDir}/nix-cache    nix-upload strategoxt-upload meta-environment-upload ut-fmt-upload
                  strategoxt   ${distDir}/strategoxt   strategoxt-upload
                  meta-environment ${distDir}/meta-environment meta-environment-upload
                  ut-fmt       ${distDir}/ut-fmt       ut-fmt-upload
                '';
              };
            }
          ];
        }

        { hostName = "strategoxt.org";
          extraSubservices = [
            { function = import /etc/nixos/nixos/upstart-jobs/apache-httpd/twiki.nix;
              config = { startWeb = "Stratego/WebHome"; };
            }
          ];
        }

        { hostName = "www.strategoxt.org";
          serverAliases = ["www.stratego-language.org"];
          extraConfig = ''
            RedirectPermanent / http://strategoxt.org/
          '';
        }

        { hostName = "svn.strategoxt.org";
          extraSubservices = [
            { function = import /etc/nixos/nixos/upstart-jobs/apache-httpd/subversion.nix;
              config = {
                urlPrefix = "";
                dataDir = "/data/subversion-strategoxt";
                notificationSender = "root@buildfarm.st.ewi.tudelft.nl";
                userCreationDomain = "st.ewi.tudelft.nl";
                organisation = {
                  name = "Stratego/XT";
                  url = http://strategoxt.org/;
                  logo = "http://strategoxt.org/pub/Stratego/StrategoLogo/StrategoLogoTextlessWhite-100px.png";
                };
              };
            }
          ];
        }

        { hostName = "program-transformation.org";
          serverAliases = ["www.program-transformation.org"];
          extraSubservices = [
            { function = import /etc/nixos/nixos/upstart-jobs/apache-httpd/twiki.nix;
              config = { startWeb = "Transform/WebHome"; };
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

        { hostName = "svn.nixos.org";
          extraSubservices = [
            { function = import /etc/nixos/nixos/upstart-jobs/apache-httpd/subversion.nix;
              config = {
                urlPrefix = "";
                dataDir = "/data/subversion-nix";
                notificationSender = "root@buildfarm.st.ewi.tudelft.nl";
                userCreationDomain = "st.ewi.tudelft.nl";
                organisation = {
                  name = "Nix";
                  url = http://nixos.org/;
                  logo = "http://www.st.ewi.tudelft.nl/serg-logo.png"; # !!! need a logo
                };
              };
            }
          ];
        }

        { hostName = "planet.strategoxt.org";
          serverAliases = ["planet.stratego.org"];
          documentRoot = "/home/karltk/public_html/planet";
        }

      ];
    };
  };

}
