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

  nixosVHostConfig =
    { hostName = "nixos.org";
      serverAliases = [ "ipv6.nixos.org" ];
      documentRoot = "/home/eelco/nix-homepage";
      enableUserDir = true;
      servedDirs =
        [ { urlPath = "/tarballs";
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

      servedFiles =
        [ { urlPath = "/releases/css/releases.css";
            file = releasesCSS;
          }
        ];

      extraConfig =
        ''
          <Proxy *>
            Order deny,allow
            Allow from all
          </Proxy>

          ProxyPreserveHost On
          
          ProxyPass         /mturk  http://wendy:3000/mturk retry=5
          ProxyPassReverse  /mturk  http://wendy:3000/mturk
          ProxyPass         /mturk-sandbox  http://wendy:3001/mturk-sandbox retry=5
          ProxyPassReverse  /mturk-sandbox  http://wendy:3001/mturk-sandbox
        '';

      extraSubservices =
        [ { serviceType = "mediawiki";
            siteName = "Nix Wiki";
            logo = "/logo/nix-wiki.png";
            defaultSkin = "nixos";
            extraConfig =
              ''
                $wgEmailConfirmToEdit = true;
              '';
            enableUploads = true;
            uploadDir = "/data/nixos-mediawiki-upload";
            dbServer = "webdsl.org";
            dbUser = "mediawiki";
            dbPassword = import ./mediawiki-password.nix;
          }
        ];
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
    vesa = false; # otherwise "out of sync" on the KVM switch
    blacklistedKernelModules = [ "i915" ];
  };

  fileSystems =
    [ { mountPoint = "/";
        label = "nixos";
        options = "acl";
      }
      { mountPoint = "/data/releases";
        device = "192.168.1.25:/data/releases";
        fsType = "nfs";
        options = "vers=3,soft"; # !!! check why vers=4 doesn't work
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
    firewall.allowedTCPPorts = [ 80 443 843 10051 5999 ];
    firewall.allowedUDPPorts = [ 53 67 ];
    firewall.rejectPackets = true;
    firewall.allowPing = true;
    firewall.extraCommands =
      ''
        ip46tables -I nixos-fw-accept -p tcp --dport 843 --syn -j LOG --log-level info --log-prefix "POLICY REQUEST: "
      '';

    nat.enable = true;
    nat.internalIPs = "192.168.1.0/22";
    nat.externalInterface = "eth1";
    nat.externalIP = myIP;
    
    localCommands =
      ''
        ${pkgs.iptables}/sbin/iptables -t nat -F PREROUTING
        
        # lucifer ssh (to give Karl/Armijn access for the BAT project)
        ${pkgs.iptables}/sbin/iptables -t nat -A PREROUTING -p tcp -d ${myIP} --dport 5950 -j DNAT --to 192.168.1.26:22

        # Cleanup.
        ip -6 route flush dev sixxs
        ip link set dev sixxs down
        ip tunnel del sixxs

        # Set up a SixXS tunnel for IPv6 connectivity.
        ip tunnel add sixxs mode sit local ${myIP} remote 192.87.102.107 ttl 64
        ip link set dev sixxs mtu 1280 up
        ip -6 addr add 2001:610:600:88d::2/64 dev sixxs
        ip -6 route add default via 2001:610:600:88d::1 dev sixxs

        # Discard all traffic to networks in our prefix that don't exist.
        ip -6 route add 2001:610:685::/48 dev lo
        
        # Create a local network (prefix:1::/64).
        ip -6 addr add 2001:610:685:1::1/64 dev eth0

        # Forward traffic to our Nova cloud to "stan".
        ip -6 route add 2001:610:685:2::/64 via 2001:610:685:1:222:19ff:fe55:bf2e

        # Amazon MTurk experiment.
        ${pkgs.iptables}/sbin/iptables -t nat -A PREROUTING -p tcp -d ${myIP} --dport 5998 -j DNAT --to 192.168.1.26:5998
        ${pkgs.iptables}/sbin/iptables -t nat -A PREROUTING -p tcp -d ${myIP} --dport 5999 -j DNAT --to 192.168.1.26:5999
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
          #"15 0 * * *  root  (TZ=CET date; ${pkgs.rsync}/bin/rsync -razv --numeric-ids --delete /data/postgresql /data/webserver/tarballs unixhome.st.ewi.tudelft.nl::bfarm/) >> /var/log/backup.log 2>&1"
          "0 3 * * * root nix-store --gc --max-freed \"$((50 * 1024**3 - 1024 * $(df /nix/store | tail -n 1 | awk '{ print $4 }')))\" > /var/log/gc.log 2>&1"
          "*  *  * * * root ${pkgs.python}/bin/python ${ZabbixApacheUpdater} -z 192.168.1.5 -c cartman"

          # Force the sixxs tunnel to stay alive by periodically
          # pinging the other side.  This is necessary to remain
          # reachable from the outside.
          "*/10 * * * * root ${pkgs.iputils}/sbin/ping6 -c 1 2001:610:600:88d::1"
        ];
    };

    httpd = {
      enable = true;
      logPerVirtualHost = true;
      adminAddr = "e.dolstra@tudelft.nl";
      hostName = "localhost";

      extraModules = ["deflate"];
      extraConfig =
        ''
          AddType application/nix-package .nixpkg
        
          <Location /server-status>
            SetHandler server-status
            Allow from 127.0.0.1 # If using a remote host for monitoring replace 127.0.0.1 with its IP. 
            Order deny,allow
            Deny from all
          </Location>
        
          ExtendedStatus On
        '';
          
      servedFiles =
        [ { urlPath = "/releases.css";
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

        { # Catch-all site.
          hostName = "www.nixos.org";
          globalRedirect = "http://nixos.org/";
        }
        
        nixosVHostConfig

        (nixosVHostConfig // {
          enableSSL = true;
          sslServerCert = "/root/ssl-secrets/ssl-nixos-org.crt";
          sslServerKey = "/root/ssl-secrets/ssl-nixos-org.key";
          extraConfig = nixosVHostConfig.extraConfig +
            ''
              SSLCertificateChainFile /root/ssl-secrets/startssl-class1.pem
              SSLCACertificateFile /root/ssl-secrets/startssl-ca.pem
              # Required by Catalyst.
              RequestHeader set X-Forwarded-Port 443
            '';
          extraSubservices = nixosVHostConfig.extraSubservices ++
            [ { function = import /etc/nixos/services/subversion;
                id = "nix";
                urlPrefix = "";
                toplevelRedirect = false;
                dataDir = "/data/subversion-nix";
                notificationSender = "svn@svn.nixos.org";
                userCreationDomain = "st.ewi.tudelft.nl";
                organisation = {
                  name = "Nix";
                  url = http://nixos.org/;
                  logo = "/logo/nixos-lores.png";
                };
              }
            ];
        })
          
        { hostName = "buildfarm.st.ewi.tudelft.nl";
          documentRoot = cleanSource ./webroot;
          enableUserDir = true;
          extraSubservices = [
            { function = import /etc/nixos/services/subversion;
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
            { function = import /etc/nixos/services/subversion;
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
          sslServerCert = "/root/ssl-secrets/server.crt";
          sslServerKey = "/root/ssl-secrets/server.key";
          globalRedirect = "http://buildfarm.st.ewi.tudelft.nl/";
        }
        
        { hostName = "strategoxt.org";
          servedFiles = [ 
            { urlPath = "/freenode.ver";
              file = "/data/pt-wiki/pub/freenode.ver";
            }
          ] ;

          extraSubservices = [
            { function = import /etc/nixos/services/twiki;
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
          sslServerCert = "/root/ssl-secrets/server.crt";
          sslServerKey = "/root/ssl-secrets/server.key";
          extraSubservices = [
            { function = import /etc/nixos/services/subversion;
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
            { function = import /etc/nixos/services/twiki;
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

        { hostName = "syntax-definition.org";
          serverAliases = ["www.syntax-definition.org"];
          extraSubservices = [
            { function = import /etc/nixos/services/twiki;
              startWeb = "Sdf/WebHome";
              dataDir = "/data/pt-wiki/data";
              pubDir = "/data/pt-wiki/pub";
              twikiName = "Syntax Definition Wiki";
              registrationDomain = "ewi.tudelft.nl";
            }
          ];
        }

        # Obsolete, kept for backwards compatibility.  Replace this
        # with a global redirect once Subversion 1.7 has been out for
        # a while
        # (http://subversion.tigris.org/issues/show_bug.cgi?id=2779).
        { hostName = "svn.nixos.org";
          enableSSL = true;
          sslServerCert = "/root/ssl-secrets/server.crt";
          sslServerKey = "/root/ssl-secrets/server.key";
          extraSubservices = [
            { function = import /etc/nixos/services/subversion;
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
          extraConfig = ''
            RedirectMatch ^/$ https://nixos.org/repoman
          '';
        }

        # Obsolete, kept for backwards compatibility.
        { hostName = "svn.nixos.org";
          globalRedirect = "https://nixos.org/svn";
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
            
            <Location />
              SetOutputFilter DEFLATE
              BrowserMatch ^Mozilla/4\.0[678] no-gzip\
              BrowserMatch \bMSI[E] !no-gzip !gzip-only-text/html
              SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary
              SetEnvIfNoCase Request_URI /api/ no-gzip dont-vary
              SetEnvIfNoCase Request_URI /download/ no-gzip dont-vary
            </Location>
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

        # Obsolete, kept for backwards compatibility.
        { hostName = "wiki.nixos.org";
          extraConfig = ''
            RedirectMatch ^/$ https://nixos.org/wiki
            Redirect / https://nixos.org/
          '';
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

        { hostName = "cloud.nixos.org";
          extraConfig = ''
            <Proxy *>
              Order deny,allow
              Allow from all
            </Proxy>

            ProxyRequests     Off
            ProxyPreserveHost On
            ProxyPass         /       http://stan:8773/ retry=5
            ProxyPassReverse  /       http://stan:8773/
          '';
        }

        { hostName = "mturk.nixos.org";
          extraConfig = ''
            <Proxy *>
              Order deny,allow
              Allow from all
            </Proxy>

            ProxyRequests     Off
            ProxyPreserveHost On
            ProxyPass         /  http://wendy/~mturk/ retry=5
            ProxyPassReverse  /  http://wendy/~mturk/
          '';
        }

        { hostName = "mturk-view.nixos.org";
          extraConfig = ''
            Redirect permanent / http://nixos.org/mturk/
          '';
        }
        
        { hostName = "mturk-view-sandbox.nixos.org";
          extraConfig = ''
            Redirect permanent / http://nixos.org/mturk-sandbox/
          '';
        }
        
      ];
    };

    sitecopy = {
      enable = true;
      backups =
        let genericBackup = { server = "webdata.tudelft.nl";
                              protocol = "webdav";
                              https = true;
                              symlinks = "ignore"; 
                            };
        in [
          ( genericBackup // { name   = "subversion";
                               local  = "/data/subversion";
                               remote = "/staff-groups/ewi/st/strategoxt/backup/subversion/subversion"; 
                             } )
          ( genericBackup // { name   = "subversion-nix";
                               local  = "/data/subversion-nix";
                               remote = "/staff-groups/ewi/st/strategoxt/backup/subversion/subversion-nix"; 
                             } )
          ( genericBackup // { name   = "subversion-ptg";
                               local  = "/data/subversion-ptg";
                               remote = "/staff-groups/ewi/st/strategoxt/backup/subversion/subversion-ptg"; 
                             } )
          ( genericBackup // { name   = "subversion-strategoxt"; 
                               local  = "/data/subversion-strategoxt";
                               remote = "/staff-groups/ewi/st/strategoxt/backup/subversion/subversion-strategoxt"; 
                             } )
          ( genericBackup // { name   = "webserver-dist-nix"; 
                               local  = "/data/webserver/dist/nix";
                               remote = "/staff-groups/ewi/st/strategoxt/backup/webserver-dist-nix"; 
                             } )
#          ( genericBackup // { name   = "webserver-tarballs"; 
#                               local  = "/data/webserver/tarballs";
#                               remote = "/staff-groups/ewi/st/strategoxt/backup/webserver-tarballs"; 
#                             } )
          ( genericBackup // { name   = "pt-wiki"; 
                               local  = "/data/pt-wiki";
                               remote = "/staff-groups/ewi/st/strategoxt/backup/pt-wiki"; 
                             } )
          ( genericBackup // { name   = "nixos-mediawiki-upload"; 
                               local  = "/data/nixos-mediawiki-upload";
                               remote = "/staff-groups/ewi/st/strategoxt/backup/nixos-mediawiki-upload"; 
                             } )
        ];
      };

    zabbixAgent.enable = true;
    
    zabbixServer.enable = true;
    zabbixServer.dbServer = "webdsl.org";
    zabbixServer.dbPassword = import ./zabbix-password.nix;

    flashpolicyd.enable = true;
    
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
    { startOn = "started network-interfaces";
      exec = "${pkgs.dnsmasq}/bin/dnsmasq --conf-file=${confFile}";
    };

}
