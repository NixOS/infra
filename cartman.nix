{ config, pkgs, ... }:

with pkgs.lib;

let 

  machines = import ./machines.nix pkgs.lib;

  # Produce the list of Nix build machines in the format expected by
  # the Nix daemon Upstart job.
  buildMachines =
    let addKey = machine: machine // 
      { sshKey = "/root/.ssh/id_buildfarm";
        sshUser = machine.buildUser;
      };
    in map addKey (filter (machine: machine ? buildUser) machines);

  myIP = "130.161.158.181";

  releasesCSS = /etc/nixos/release/generic-dist/release-page/releases.css;

  ZabbixApacheUpdater = pkgs.fetchsvn {
    url = https://www.zulukilo.com/svn/pub/zabbix-apache-stats/trunk/fetch.py;
    sha256 = "1q66x429wpqjqcmlsi3x37rkn95i55nj8ldzcrblnx6a0jnjgd2g";
    rev = 94;
  };

in

rec {
  require = [ ./common.nix ];

  nixpkgs.system = "i686-linux";

  boot = {
    loader.grub.device = "/dev/sda";
    loader.grub.copyKernels = true;
    initrd.kernelModules = ["arcmsr"];
    kernelModules = ["kvm-intel"];
  };

  fileSystems =
    [ { mountPoint = "/";
        label = "nixos";
        options = "acl";
      }
      { mountPoint = "/data/releases";
        device = "192.168.1.25:/data/releases";
        fsType = "nfs";
        options = "vers=3"; # !!! check why vers=4 doesn't work
      }
    ];

  swapDevices = [
    { label = "swap1"; }
  ];
  
  nix = {
    maxJobs = 2;
    distributedBuilds = true;
    inherit buildMachines;
    extraOptions = ''
      gc-keep-outputs = true
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
        ipAddress = (findSingle (m: m.hostName == "cartman") {} {} machines).ipAddress;
        subnetMask = "22";
      }
    ];

    defaultGateway = "130.161.158.1";

    nameservers = [ "127.0.0.1" ];

    extraHosts = "192.168.1.5 cartman";

    firewall.enable = true;
    firewall.allowedTCPPorts = [ 80 443 10051 ];
    firewall.allowedUDPPorts = [ 53 67 ];
    firewall.rejectPackets = true;
    firewall.allowPing = true;

    nat.enable = true;
    nat.internalIPs = "192.168.1.0/22";
    nat.externalInterface = "eth1";
    nat.externalIP = myIP;
    
    localCommands =
      ''
        # lucifer ssh (to give Karl/Armijn access for the BAT project)
        #iptables -t nat -A PREROUTING -p tcp -i eth1 --dport 22222 -j DNAT --to 192.168.1.25:22

        # Cleanup.
        ip -6 route flush dev sixxs
        ip link set dev sixxs down
        ip tunnel del sixxs

        # Set up a SixXS tunnel for IPv6 connectivity.
        ip tunnel add sixxs mode sit local 130.161.158.181 remote 192.87.102.107 ttl 64
        ip link set dev sixxs mtu 1280 up
        ip -6 addr add 2001:610:600:88d::2/64 dev sixxs
        ip -6 route add default via 2001:610:600:88d::1 dev sixxs

        # Discard all traffic to networks in our prefix that don't exist.
        ip -6 route add 2001:610:685::/48 dev lo
        
        # Create a local network (prefix:1::/64).
        ip -6 addr add 2001:610:685:1::1/64 dev eth0
      '';
  };

  services = {

    radvd = {
      enable = true;
      config =
        ''
          interface eth0 {
            AdvSendAdvert on;
            prefix 2001:610:685:1::/64 { };
            RDNSS 2001:610:685:1::1 { };
          };
        '';
    };
  
    cron = {
      mailto = "rob.vermaas@gmail.com";
      systemCronJobs =
        [
          "15 0 * * *  root  (TZ=CET date; ${pkgs.rsync}/bin/rsync -razv --numeric-ids --delete /data/postgresql /data/webserver/tarballs unixhome.st.ewi.tudelft.nl::bfarm/) >> /var/log/backup.log 2>&1"
          "00 03 * * * root ${pkgs.nixUnstable}/bin/nix-collect-garbage --max-atime $(date +\\%s -d '2 weeks ago') > /var/log/gc.log 2>&1"
          "*  *  * * * root ${pkgs.python}/bin/python ${ZabbixApacheUpdater} -z 192.168.1.5 -c cartman"

          # Force the sixxs tunnel to stay alive by periodically
          # pinging the other side.  This is necessary to remain
          # reachable from the outside.
          "*/10 * * * * root ${pkgs.iputils}/sbin/ping6 -c 1 2001:610:600:88d::1"
        ];
    };

    postgresql = {
      enable = true;
      enableTCPIP = true;
      dataDir = "/data/postgresql";
      authentication = ''
          local all mediawiki        ident mediawiki-users
          local all all              ident sameuser
          host  all all 127.0.0.1/32 md5
          host  all all ::1/128      md5
          host  all all 192.168.1.18/32  md5
          host  all all 130.161.159.80/32 md5
          host  all all 94.208.32.143/32 md5
        '';
    };

    httpd = {
      enable = true;
      logPerVirtualHost = true;
      adminAddr = "e.dolstra@tudelft.nl";
      hostName = "localhost";

      sslServerCert = "/root/ssl-secrets/server.crt";
      sslServerKey = "/root/ssl-secrets/server.key";
          
      extraConfig = ''
        AddType application/nix-package .nixpkg

        SSLProtocol all -TLSv1

        <Location /server-status>
                SetHandler server-status
                Allow from 127.0.0.1 # If using a remote host for monitoring replace 127.0.0.1 with its IP. 
                Order deny,allow
                Deny from all
        </Location>
        ExtendedStatus On
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
          documentRoot = cleanSource ./webroot;
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
              dataDir = "/data/pt-wiki/data";
              pubDir = "/data/pt-wiki/pub";
              twikiName = "Stratego/XT Wiki";
              registrationDomain = "ewi.tudelft.nl";
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
              dataDir = "/data/pt-wiki/data";
              pubDir = "/data/pt-wiki/pub";
              twikiName = "Program Transformation Wiki";
              registrationDomain = "ewi.tudelft.nl";
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
            ProxyPass         /       http://mrkitty:10080/
            ProxyPassReverse  /       http://mrkitty:10080/
          '';
        }

        { hostName = "releases.strategoxt.org";
          documentRoot = "/data/webserver/dist/strategoxt2";
        }

        { hostName = "nixos.org";
          serverAliases = [ "ipv6.nixos.org" ];
          documentRoot = "/home/eelco/nix-homepage";
          servedDirs = [
            { urlPath = "/tarballs";
              dir = "/data/webserver/tarballs";
            }
            { urlPath = "/irc";
              dir = "/data/webserver/irc";
            }
            { urlPath = "/update";
              dir = "/data/webserver/update";
            }
            { urlPath = "/releases";
              dir = "/data/releases";
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
                logo = http://nixos.org/logo/nixos-lores.png;
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
            ProxyPass         /       http://lucifer:3000/ retry=5
            ProxyPassReverse  /       http://lucifer:3000/
          '';
        }

        { hostName = "hydra-ubuntu.nixos.org";
          extraConfig = ''
            <Proxy *>
              Order deny,allow
              Allow from all
            </Proxy>

            ProxyRequests     Off
            ProxyPreserveHost On
            ProxyPass         /       http://meerkat:3000/ retry=5
            ProxyPassReverse  /       http://meerkat:3000/
          '';
        }

        { hostName = "wiki.nixos.org";
          extraConfig = ''
            RedirectMatch ^/$ /wiki
          '';
          extraSubservices = [
            { serviceType = "mediawiki";
              siteName = "Nix Wiki";
              logo = "http://nixos.org/logo/nix-wiki.png";
              extraConfig =
                ''
                  $wgEmailConfirmToEdit = true;
                '';
              enableUploads = true;
              uploadDir = "/data/nixos-mediawiki-upload";
            }
          ];
        }

        { hostName = "planet.strategoxt.org";
          serverAliases = ["planet.stratego.org"];
          documentRoot = "/home/karltk/public_html/planet";
        }

        { hostName = "sonar.nixos.org";
          extraConfig = ''
            <Proxy *>
              Order deny,allow
              Allow from all
            </Proxy>

            ProxyRequests     Off
            ProxyPreserveHost On
            ProxyPass         /       http://lucifer:8080/ retry=5
            ProxyPassReverse  /       http://lucifer:8080/
          '';
        }
      ];
    };

    sitecopy = {
      enable = true;
      backups =
        let genericBackup = { server = "webdata.tudelft.nl";
                              protocol = "webdav";
                              https = true ;
                              symlinks = "ignore"; 
                            };
        in [
          ( genericBackup // { name   = "postgresql";
                               local  = config.services.postgresqlBackup.location;
                               remote = "/staff-groups/ewi/st/strategoxt/backup/postgresql"; 
                             } )
          ( genericBackup // { name   = "subversion";
                               local  = "/data/subversion";
                               remote = "/staff-groups/ewi/st/strategoxt/backup/subversion/subversion"; 
                             } )
          ( genericBackup // { name   = "subversion-nix";
                               local  = "/data/subversion-nix";
                               remote = "/staff-groups/ewi/st/strategoxt/backup/subversion/subversion-nix"; 
                               period = "15 03 * * *"; 
                             } )
          ( genericBackup // { name   = "subversion-ptg";
                               local  = "/data/subversion-ptg";
                               remote = "/staff-groups/ewi/st/strategoxt/backup/subversion/subversion-ptg"; 
                             } )
          ( genericBackup // { name   = "subversion-strategoxt"; 
                               local  = "/data/subversion-strategoxt";
                               remote = "/staff-groups/ewi/st/strategoxt/backup/subversion/subversion-strategoxt"; 
                               period = "15 02 * * *"; 
                             } )
          ( genericBackup // { name   = "webserver-dist-nix"; 
                               local  = "/data/webserver/dist/nix";
                               remote = "/staff-groups/ewi/st/strategoxt/backup/webserver-dist-nix"; 
                               period = "5 03 * * *"; 
                             } )
#          ( genericBackup // { name   = "webserver-tarballs"; 
#                               local  = "/data/webserver/tarballs";
#                               remote = "/staff-groups/ewi/st/strategoxt/backup/webserver-tarballs"; 
#                               period = "5 03 * * *"; 
#                             } )
          ( genericBackup // { name   = "pt-wiki"; 
                               local  = "/data/pt-wiki";
                               remote = "/staff-groups/ewi/st/strategoxt/backup/pt-wiki"; 
                               period = "55 02 * * *"; 
                             } )
          ( genericBackup // { name   = "nixos-mediawiki-upload"; 
                               local  = "/data/nixos-mediawiki-upload";
                               remote = "/staff-groups/ewi/st/strategoxt/backup/nixos-mediawiki-upload"; 
                               period = "20 03 * * *"; 
                             } )
        ];
      };

    zabbixAgent.enable = true;
    
    zabbixServer.enable = true;
    zabbixServer.dbServer = "lucifer";
    zabbixServer.dbPassword = import ./zabbix-password.nix;

  };

  # Needed for the Nixpkgs mirror script.
  environment.pathsToLink = [ "/libexec" ];

  environment.systemPackages = [ pkgs.dnsmasq ];
  
  jobs.dnsmasq =
    let
    
      confFile = pkgs.writeText "dnsmasq.conf"
        ''
          keep-in-foreground
          no-hosts
          addn-hosts=${hostsFile}
          expand-hosts
          domain=buildfarm
          interface=eth0

          server=130.161.158.4
          server=130.161.33.17
          server=130.161.180.1

          dhcp-range=192.168.1.150,192.168.3.200

          ${flip concatMapStrings machines (m: optionalString (m ? ethernetAddress) ''
            dhcp-host=${m.ethernetAddress},${m.ipAddress},${m.hostName}
          '')}
        '';
        
      hostsFile = pkgs.writeText "extra-hosts"
        (flip concatMapStrings machines (m: "${m.ipAddress} ${m.hostName}\n"));
        
    in
    { startOn = "network-interfaces";
      exec = "${pkgs.dnsmasq}/bin/dnsmasq --conf-file=${confFile}";
    };
  
}
