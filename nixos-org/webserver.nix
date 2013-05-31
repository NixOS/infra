{ config, pkgs, resources, ... }:

with pkgs.lib;

let

  nixosVHostConfig =
    { hostName = "nixos.org";
      serverAliases = [ "test.nixos.org" "test2.nixos.org" "ipv6.nixos.org" ];
      documentRoot = "/home/eelco/nix-homepage";
      enableUserDir = true;
      servedDirs =
        [ { urlPath = "/tarballs";
            dir = "/tarballs";
          }
          /*
          { urlPath = "/irc";
            dir = "/data/webserver/irc";
          }
          { urlPath = "/update";
            dir = "/data/webserver/update";
          }
          */
          # Backwards compatibility.
          { urlPath = "/releases/nixpkgs/channels";
            dir = "/releases/channels";
          }
          # Backwards compatibility.
          { urlPath = "/releases/nixos/channels";
            dir = "/releases/channels";
          }
          { urlPath = "/channels";
            dir = "/releases/channels";
          }
          { urlPath = "/releases";
            dir = "/releases";
          }
          /*
          { urlPath = "/binary-cache";
            dir = "/data/releases/binary-cache";
          }
          */
        ];

      extraConfig =
        ''
          #<Proxy *>
          #  Order deny,allow
          #  Allow from all
          #</Proxy>
          #
          #ProxyPreserveHost On
          #
          #ProxyPass         /mturk  http://wendy:3000/mturk retry=5
          #ProxyPassReverse  /mturk  http://wendy:3000/mturk
          #ProxyPass         /mturk-sandbox  http://wendy:3001/mturk-sandbox retry=5
          #ProxyPassReverse  /mturk-sandbox  http://wendy:3001/mturk-sandbox

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
            #skins = [ ./wiki-skins ];
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
          }
          { function = import <services/subversion>;
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
    };

in

{
  security.pam.enableSSHAgentAuth = true;

  services.httpd = {
    enable = true;
    multiProcessingModule = "worker";
    logPerVirtualHost = true;
    adminAddr = "eelco.dolstra@logicblox.com";
    hostName = "localhost";

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

    virtualHosts =
      [ { # Catch-all site.
          hostName = "www.nixos.org";
          globalRedirect = "http://nixos.org/";
        }

        nixosVHostConfig

        { hostName = "tarballs.nixos.org";
          documentRoot = "/tarballs";
        }

        # Obsolete, kept for backwards compatibility.
        { hostName = "svn.nixos.org";
          globalRedirect = "https://nixos.org/repoman";
        }

        # Obsolete, kept for backwards compatibility.
        { hostName = "wiki.nixos.org";
          extraConfig = ''
            RedirectMatch ^/$ https://nixos.org/wiki
            Redirect / https://nixos.org/
          '';
        }
      ];
  };

  users.extraUsers.eelco =
    { createHome = true;
      description = "Eelco Dolstra";
      extraGroups = [ "wheel" ];
      group = "users";
      home = "/home/eelco";
      isSystemUser = false;
      useDefaultShell = true;
      openssh.authorizedKeys.keys =
        [ "ssh-dss AAAAB3NzaC1kc3MAAACBAOo3foMFsYvc+LEVVTAeXpaxdOFG6O2NE9coxZYN6UtwE477GwkvZ4uKymAekq3TB8I6dDg4QFfE27fIip/rQHJ/Rus+KsxwnTbwPzE0WcZVpkKQsepsoqLkfwMpiPfn5/oxcnJsimwRY/E95aJmmOHdGaYWrc0t4ARa+6teUgdFAAAAFQCSQq2Wil0/X4hDypGGUKlKvYyaWQAAAIAy/0fSDnz1tZOQBGq7q78y406HfWghErrVlrW9g+foJQG5pgXXcdJs9JCIrlaKivUKITDsYnQaCjrZaK8eHnc4ksbkSLfDOxFnR5814ulCftrgEDOv9K1UU3pYketjFMvQCA2U48lR6jG/99CPNXPH55QEFs8H97cIsdLQw9wM4gAAAIEAmzWZlXLzIf3eiHQggXqvw3+C19QvxQITcYHYVTx/XYqZi1VZ/fkY8bNmdcJsWFyOHgEhpEca+xM/SNvH/14rXDmt0wtclLEx/4GVLi59hQCnnKqv7HzJg8RF4v6XTiROBAEEdb4TaFuFn+JCvqPzilTzXTexvZKJECOvfYcY+10= eelco.dolstra@logicblox.com" ];
    };

  users.extraUsers.tarball-mirror =
    { description = "Nixpkg starball mirroring user";
      home = "/home/tarball-mirror";
      createHome = true;
      useDefaultShell = true;
      openssh.authorizedKeys.keys = singleton "ssh-dss AAAAB3NzaC1kc3MAAACBAOo3foMFsYvc+LEVVTAeXpaxdOFG6O2NE9coxZYN6UtwE477GwkvZ4uKymAekq3TB8I6dDg4QFfE27fIip/rQHJ/Rus+KsxwnTbwPzE0WcZVpkKQsepsoqLkfwMpiPfn5/oxcnJsimwRY/E95aJmmOHdGaYWrc0t4ARa+6teUgdFAAAAFQCSQq2Wil0/X4hDypGGUKlKvYyaWQAAAIAy/0fSDnz1tZOQBGq7q78y406HfWghErrVlrW9g+foJQG5pgXXcdJs9JCIrlaKivUKITDsYnQaCjrZaK8eHnc4ksbkSLfDOxFnR5814ulCftrgEDOv9K1UU3pYketjFMvQCA2U48lR6jG/99CPNXPH55QEFs8H97cIsdLQw9wM4gAAAIEAmzWZlXLzIf3eiHQggXqvw3+C19QvxQITcYHYVTx/XYqZi1VZ/fkY8bNmdcJsWFyOHgEhpEca+xM/SNvH/14rXDmt0wtclLEx/4GVLi59hQCnnKqv7HzJg8RF4v6XTiROBAEEdb4TaFuFn+JCvqPzilTzXTexvZKJECOvfYcY+10= eelco.dolstra@logicblox.com";
    };

  system.activationScripts.setShmMax =
    ''
      ${pkgs.procps}/sbin/sysctl -q -w kernel.shmmax=$((1 * 1024**3))
    '';

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql92;
    extraConfig = ''
      max_connections = 10
      work_mem = 16MB
      shared_buffers = 512MB
      # We can risk losing some transactions.
      synchronous_commit = off
    '';
    authentication = pkgs.lib.mkOverride 10 ''
      local mediawiki all ident map=mwusers
      local all       all ident
    '';
    identMap = ''
      mwusers root   mediawiki
      mwusers wwwrun mediawiki
    '';
  };
}
