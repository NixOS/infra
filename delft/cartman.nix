{ config, pkgs, ... }:

with pkgs.lib;

let

  zabbixMail = pkgs.writeScriptBin "zabbix-mail" ''
    #!/bin/sh
    set -e

    export zabbixemailto="$1"
    export zabbixsubject="$2"
    export zabbixbody="$3"

    ${pkgs.ssmtp}/sbin/sendmail -v $zabbixemailto <<EOF
    Subject: $zabbixsubject
    To: $zabbixemailto
    
    $zabbixbody
    EOF
  '';

  duplicityBackup = pkgs.writeScript "backup-duplicity" ''
    #! /bin/sh
    echo "Starting backups"
    export PATH=$PATH:/var/run/current-system/sw/bin
    time duplicity --full-if-older-than 30D --no-encryption /data/pt-wiki file:///backup/cartman/pt-wiki
    time duplicity --no-encryption --force remove-all-inc-of-but-n-full 1 file:///backup/cartman/pt-wiki

    time duplicity --full-if-older-than 30D --no-encryption /data/nixos-mediawiki-upload file:///backup/cartman/nixos-mediawiki-upload
    time duplicity --no-encryption --force remove-all-inc-of-but-n-full 1 file:///backup/cartman/nixos-mediawiki-upload

    time duplicity --full-if-older-than 30D --no-encryption /data/subversion file:///backup/cartman/subversion
    time duplicity --no-encryption --force remove-all-inc-of-but-n-full 1 file:///backup/cartman/subversion

    time duplicity --full-if-older-than 30D --no-encryption /data/subversion-nix file:///backup/cartman/subversion-nix
    time duplicity --no-encryption --force remove-all-inc-of-but-n-full 1 file:///backup/cartman/subversion-nix

    time duplicity --full-if-older-than 30D --no-encryption /data/subversion-ptg file:///backup/cartman/subversion-ptg
    time duplicity --no-encryption --force remove-all-inc-of-but-n-full 1 file:///backup/cartman/subversion-ptg

    time duplicity --full-if-older-than 30D --no-encryption /data/subversion-strategoxt file:///backup/cartman/subversion-strategoxt
    time duplicity --no-encryption --force remove-all-inc-of-but-n-full 1 file:///backup/cartman/subversion-strategoxt

    echo Done
  '';

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
          # Backwards compatibility.
          { urlPath = "/releases/nixpkgs/channels";
            dir = "/data/releases/channels";
          }
          # Backwards compatibility.
          { urlPath = "/releases/nixos/channels";
            dir = "/data/releases/channels";
          }
          { urlPath = "/channels";
            dir = "/data/releases/channels";
          }
          { urlPath = "/releases";
            dir = "/data/releases";
          }
          { urlPath = "/binary-cache";
            dir = "/data/releases/binary-cache";
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

          MaxKeepAliveRequests 0

          # Use a very short error message for 404s in the binary
          # cache, since those are very frequent and not generally
          # seen by humans.
          <Location /releases/binary-cache>
            ErrorDocument 404 "No such file."
          </Location>
        '';

      extraSubservices =
        [ { serviceType = "mediawiki";
            siteName = "Nix Wiki";
            logo = "/logo/nix-wiki.png";
            #defaultSkin = "nixos";
            skins = [ ./wiki-skins ];
            extraConfig =
              ''
                #$wgEmailConfirmToEdit = true;

                # Use a reCAPTCHA to prevent spam.
                require_once("$IP/extensions/ConfirmEdit/ConfirmEdit.php");
                require_once("$IP/extensions/ConfirmEdit/ReCaptcha.php");
                $wgCaptchaClass = 'ReCaptcha';
                $wgReCaptchaPublicKey = '6Ldevd8SAAAAAFR6MwnU01FOWJ3O4II3aRJpMQ8F';
                $wgReCaptchaPrivateKey = '${builtins.readFile ./nixos.org-recaptcha-private-key}';
                $wgCaptchaTriggers['edit']          = true;
                $wgCaptchaTriggers['create']        = true;
              '';
            enableUploads = true;
            uploadDir = "/data/nixos-mediawiki-upload";
            dbServer = "wendy";
            dbUser = "mediawiki";
            dbPassword = import ./mediawiki-password.nix;
          }
        ];
    };

  strategoxtVHostConfig =
    { hostName = "strategoxt.org";
      servedFiles = [
        { urlPath = "/freenode.ver";
          file = "/data/pt-wiki/pub/freenode.ver";
        }
      ];
      extraSubservices = [
        { function = import /etc/nixos/services/twiki;
          startWeb = "Stratego/WebHome";
          dataDir = "/data/pt-wiki/data";
          pubDir = "/data/pt-wiki/pub";
          twikiName = "Stratego/XT Wiki";
          registrationDomain = "ewi.tudelft.nl";
        }
      ];
    };

  strategoxtSSLConfig =
    { enableSSL = true;
      sslServerCert = "/root/ssl-secrets/ssl-strategoxt-org.crt";
      sslServerKey = "/root/ssl-secrets/ssl-strategoxt-org.key";
      extraConfig =
        ''
          SSLCertificateChainFile /root/ssl-secrets/startssl-class1.pem
          SSLCACertificateFile /root/ssl-secrets/startssl-ca.pem
        '';
    };

in

rec {
  require = [ ./common.nix ];

  nixpkgs.system = "x86_64-linux";

  boot = {
    loader.grub.device = "/dev/sda";
    loader.grub.copyKernels = true;
    initrd.kernelModules = ["arcmsr"];
    kernelModules = ["kvm-intel"];
  };

  fileSystems."/" =
    { label = "nixos";
      options = "acl";
    };
  fileSystems."/data/releases" =
    { device = "192.168.1.25:/";
      fsType = "nfs4";
      options = "soft";
    };
  fileSystems."/backup" =
    { device = "130.161.158.5:/dxs/users4/group/buildfarm";
      fsType = "nfs4";
    };

  #swapDevices = [ { label = "swap1"; } ];

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

    interfaces.external =
      { ipAddress = myIP;
        prefixLength = 23;
      };

    interfaces.internal =
      { ipAddress = (findSingle (m: m.hostName == "cartman") {} {} machines).ipAddress;
        prefixLength = 22;
      };

    useDHCP = false;

    defaultGateway = "130.161.158.1";

    nameservers = [ "127.0.0.1" ];

    extraHosts = "192.168.1.5 cartman";

    firewall.allowedTCPPorts = [ 80 443 843 10051 5999 ];
    firewall.allowedUDPPorts = [ 53 67 ];
    firewall.extraCommands =
      ''
        ip46tables -I nixos-fw-accept -p tcp --dport 843 --syn -j LOG --log-level info --log-prefix "POLICY REQUEST: "
      '';

    nat.enable = true;
    nat.internalIPs = "192.168.1.0/22";
    nat.externalInterface = "external";
    nat.externalIP = myIP;

    localCommands =
      ''
        ${pkgs.iptables}/sbin/iptables -t nat -F PREROUTING

        # lucifer ssh (to give Karl/Armijn access for the BAT project)
        ${pkgs.iptables}/sbin/iptables -t nat -A PREROUTING -p tcp -d ${myIP} --dport 2222 -j DNAT --to 192.168.1.26:22

        # Cleanup.
        ip -6 route flush dev sixxs || true
        ip link set dev sixxs down || true
        ip tunnel del sixxs || true

        # Set up a SixXS tunnel for IPv6 connectivity.
        ip tunnel add sixxs mode sit local ${myIP} remote 192.87.102.107 ttl 64
        ip link set dev sixxs mtu 1280 up
        ip -6 addr add 2001:610:600:88d::2/64 dev sixxs
        ip -6 route add default via 2001:610:600:88d::1 dev sixxs

        # Discard all traffic to networks in our prefix that don't exist.
        ip -6 route add 2001:610:685::/48 dev lo || true

        # Create a local network (prefix:1::/64).
        ip -6 addr add 2001:610:685:1::1/64 dev internal || true

        # Forward traffic to our Nova cloud to "stan".
        ip -6 route add 2001:610:685:2::/64 via 2001:610:685:1:222:19ff:fe55:bf2e || true

        # Amazon MTurk experiment.
        #${pkgs.iptables}/sbin/iptables -t nat -A PREROUTING -p tcp -d ${myIP} --dport 5998 -j DNAT --to 192.168.1.26:5998
        #${pkgs.iptables}/sbin/iptables -t nat -A PREROUTING -p tcp -d ${myIP} --dport 5999 -j DNAT --to 192.168.1.26:5999
      '';
  };

  services = {

    udev.extraRules =
      ''
        ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="00:19:d1:19:28:bf", NAME="external"
        ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="00:04:23:df:f7:bf", NAME="internal"
      '';

    radvd = {
      enable = true;
      config =
        ''
          interface internal {
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
          "*  *  * * * root ${pkgs.python}/bin/python ${ZabbixApacheUpdater} -z 192.168.1.5 -c cartman"
          "40 * * * *  root ${duplicityBackup} &>> /var/log/backup-duplicity.log"
          "30 1 * * *  root ${config.systemd.package}/bin/systemctl start mirror-tarballs.service"

          # Force the sixxs tunnel to stay alive by periodically
          # pinging the other side.  This is necessary to remain
          # reachable from the outside.
          "*/10 * * * * root ${pkgs.iputils}/sbin/ping6 -c 1 2001:610:600:88d::1"
        ];
    };

    httpd = {
      enable = true;
      multiProcessingModule = "worker";
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

          StartServers 15
        '';

      phpOptions =
        ''
          #max_execution_time = 2
          memory_limit = "32M"
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

        strategoxtVHostConfig

        (strategoxtVHostConfig // strategoxtSSLConfig)

        { hostName = "www.strategoxt.org";
          serverAliases = ["www.stratego-language.org"];
          globalRedirect = "http://strategoxt.org/";
        }

        { hostName = "svn.strategoxt.org";
          globalRedirect = "https://svn.strategoxt.org/";
        }

        ( strategoxtSSLConfig //
        { hostName = "svn.strategoxt.org";
          extraSubservices = [
            { function = import /etc/nixos/services/subversion;
              id = "strategoxt";
              urlPrefix = "";
              dataDir = "/data/subversion-strategoxt";
              notificationSender = "svn@svn.strategoxt.org";
              organisation = {
                name = "Stratego/XT";
                url = http://strategoxt.org/;
                logo = http://strategoxt.org/pub/Stratego/StrategoLogo/StrategoLogoTextlessWhite-100px.png;
              };
            }
          ];
        })

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

        # Obsolete, kept for backwards compatibility.
        { hostName = "svn.nixos.org";
          enableSSL = true;
          sslServerCert = "/root/ssl-secrets/server.crt";
          sslServerKey = "/root/ssl-secrets/server.key";
          extraConfig = ''
            RedirectMatch permanent ^/$ https://nixos.org/repoman
            Redirect permanent / https://nixos.org/
          '';
        }

        # Obsolete, kept for backwards compatibility.
        { hostName = "svn.nixos.org";
          globalRedirect = "https://nixos.org/repoman";
        }

        { hostName = "hydra.nixos.org";
          logFormat = ''"%h %l %u %t \"%r\" %>s %b %D"'';
          extraConfig = ''
            TimeOut 900

            <Proxy *>
              Order deny,allow
              Allow from all
            </Proxy>

            ProxyRequests     Off
            ProxyPreserveHost On
            ProxyPass         /       http://lucifer:3000/ retry=5 disablereuse=on
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

        { hostName = "hydra-test.nixos.org";
          logFormat = ''"%h %l %u %t \"%r\" %>s %b %D"'';
          extraConfig = ''
            <Proxy *>
              Order deny,allow
              Allow from all
            </Proxy>

            ProxyRequests     Off
            ProxyPreserveHost On
            ProxyPass         /       http://wendy:4000/ retry=5 disablereuse=off
            ProxyPassReverse  /       http://wendy:4000/
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

        /*
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
        */

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

    zabbixAgent.enable = true;

    zabbixServer.enable = true;
    zabbixServer.dbServer = "wendy";
    zabbixServer.dbPassword = import ./zabbix-password.nix;

    flashpolicyd.enable = true;

  };

  # Needed for the Nixpkgs mirror script.
  environment.pathsToLink = [ "/libexec" ];

  environment.systemPackages = [ pkgs.dnsmasq pkgs.duplicity zabbixMail ];

  jobs.dnsmasq =
    let

      confFile = pkgs.writeText "dnsmasq.conf"
        ''
          keep-in-foreground
          no-hosts
          addn-hosts=${hostsFile}
          expand-hosts
          domain=buildfarm
          interface=internal

          server=130.161.158.4
          server=130.161.33.17
          server=130.161.180.1
          server=8.8.8.8
          server=8.8.4.4

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

  # Use cgroups to limit Apache's resources.
  systemd.services.httpd.serviceConfig.CPUShares = 1000;
  systemd.services.httpd.serviceConfig.MemoryLimit = "1500M";
  systemd.services.httpd.serviceConfig.ControlGroupAttribute = [ "memory.memsw.limit_in_bytes 1500M" ];

  users.extraUsers.tarball-mirror =
    { description = "Nixpkg starball mirroring user";
      home = "/home/tarball-mirror";
      createHome = true;
      useDefaultShell = true;
      openssh.authorizedKeys.keys = singleton "ssh-dss AAAAB3NzaC1kc3MAAACBAOo3foMFsYvc+LEVVTAeXpaxdOFG6O2NE9coxZYN6UtwE477GwkvZ4uKymAekq3TB8I6dDg4QFfE27fIip/rQHJ/Rus+KsxwnTbwPzE0WcZVpkKQsepsoqLkfwMpiPfn5/oxcnJsimwRY/E95aJmmOHdGaYWrc0t4ARa+6teUgdFAAAAFQCSQq2Wil0/X4hDypGGUKlKvYyaWQAAAIAy/0fSDnz1tZOQBGq7q78y406HfWghErrVlrW9g+foJQG5pgXXcdJs9JCIrlaKivUKITDsYnQaCjrZaK8eHnc4ksbkSLfDOxFnR5814ulCftrgEDOv9K1UU3pYketjFMvQCA2U48lR6jG/99CPNXPH55QEFs8H97cIsdLQw9wM4gAAAIEAmzWZlXLzIf3eiHQggXqvw3+C19QvxQITcYHYVTx/XYqZi1VZ/fkY8bNmdcJsWFyOHgEhpEca+xM/SNvH/14rXDmt0wtclLEx/4GVLi59hQCnnKqv7HzJg8RF4v6XTiROBAEEdb4TaFuFn+JCvqPzilTzXTexvZKJECOvfYcY+10= eelco.dolstra@logicblox.com";
    };

  systemd.services.mirror-tarballs =
    { description = "Mirror Nixpkgs tarballs";
      path  = [ config.environment.nix pkgs.curl pkgs.git ];
      #environment.DRY_RUN = "1";
      environment.HYDRA_DISALLOW_UNFREE = "1";
      environment.NIX_PATH = "nixpkgs=/home/tarball-mirror/nixpkgs";
      environment.NIX_REMOTE = "daemon";
      environment.CURL_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";
      serviceConfig.User = "tarball-mirror";
      script =
        ''
          export NIX_CURL_FLAGS="--silent --show-error --connect-timeout 30"
          cd /home/tarball-mirror/nixpkgs
          git pull
          exec /etc/nixos/nixpkgs/maintainers/scripts/copy-tarballs.sh
        '';
    };

}
