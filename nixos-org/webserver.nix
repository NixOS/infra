{ config, lib, pkgs, resources, ... }:

with lib;

let

  sshKeys = import ../ssh-keys.nix;

  commonConfig =
    ''
      MaxKeepAliveRequests 0

      Redirect /binary-cache https://cache.nixos.org
      Redirect /releases/channels /channels
      Redirect /tarballs http://tarballs.nixos.org
      Redirect /releases/nixos https://releases.nixos.org/nixos
      # Added for https://github.com/NixOS/nixos-homepage/pull/318
      Redirect /nixos/support.html /nixos/learn.html

      # Don't allow access to .git directories.
      RewriteEngine on
      RewriteRule "^(.*/)?\.git/" - [F,L]

      RedirectMatch "^/wiki.*" "https://nixos.org/nixos/wiki.html"

      <Location /server-status>
        SetHandler server-status
        Require ip 127.0.0.1
      </Location>

      <Location /irc>
        ForceType text/plain
      </Location>
    '';

in

{
  networking.firewall.enable = true;
  networking.firewall.rejectPackets = true;
  networking.firewall.allowPing = true;
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  networking.defaultMailServer = {
    directDelivery = true;
    hostName = "smtp.tudelft.nl";
    domain = "st.ewi.tudelft.nl";
  };

  environment.systemPackages = [ pkgs.perlPackages.XMLSimple pkgs.git pkgs.openssl ];

  nix.package = pkgs.nixUnstable;

  nix.nixPath = [ "nixpkgs=channel:nixos-18.09-small" ];

  security.pam.enableSSHAgentAuth = true;

  services.httpd = {
    enable = true;
    #multiProcessingModule = "worker";
    adminAddr = "edolstra@gmail.com";
    sslProtocol = "All -SSLv2 -SSLv3";

    extraConfig =
      ''
        AddType application/nix-package .nixpkg
        AddType text/plain .sha256

        # Serve the package/option databases as automatically
        # decompressed JSON.
        AddEncoding x-gzip gz

        #StartServers 15

        ExtendedStatus On
      '';

    phpOptions =
      ''
        ;max_execution_time = 2
        memory_limit = "32M"
      '';

    virtualHosts."nixos.org" =
      {
        serverAliases = [ "test.nixos.org" "test2.nixos.org" "ipv6.nixos.org" "localhost" ];
        forceSSL = true;
        enableACME = true;
        enableUserDir = true;
        documentRoot = "/home/homepage/nixos-homepage";
        extraConfig = commonConfig + ''
          Header always set Strict-Transport-Security "max-age=15552000"
        '';

        servedDirs =
          [ { urlPath = "/irc";
              dir = "/data/irc";
            }
            { urlPath = "/channels";
              dir = "/releases/channels";
            }
            { urlPath = "/releases";
              dir = "/releases";
            }
          ];

        robotsEntries =
          ''
            User-agent: *
            Disallow: /repos/
            Disallow: /irc/
          '';
      };

    virtualHosts."planet.nixos.org" =
      {
        forceSSL = true;
        enableACME = true;
        documentRoot = "/var/www/planet.nixos.org";
        extraConfig = commonConfig +
          ''
            Header always set Strict-Transport-Security "max-age=15552000"
          '';
      };
  };

  users.users.eelco =
    { createHome = true;
      description = "Eelco Dolstra";
      extraGroups = [ "wheel" ];
      group = "users";
      home = "/home/eelco";
      isSystemUser = false;
      useDefaultShell = true;
      openssh.authorizedKeys.keys = [ sshKeys.eelco ];
      uid = 1000;
    };

  users.users.rbvermaa =
    { createHome = true;
      description = "Rob Vermaas";
      extraGroups = [ "wheel" ];
      group = "users";
      home = "/home/rbvermaa";
      isSystemUser = false;
      useDefaultShell = true;
      openssh.authorizedKeys.keys = [ sshKeys.rob ];
      uid = 1001;
    };

  users.users.irclogs =
    { createHome = true;
      description = "#nixos IRC Logging";
      group = "users";
      home = "/home/irclogs";
      isSystemUser = false;
      useDefaultShell = true;
      openssh.authorizedKeys.keys =
        [ "ssh-dss AAAAB3NzaC1kc3MAAACBAMrcUf4qQj8XcG1nfG5/6rbfb4a89nV13KcJLBOVWa3Tn4YHeVz1lQDRHvnLK9YKM7MybDXD2wVG5nKuMbJMW5aZPEGrVUM4SQFXtnaNBgmoACrbG978Da/vNjGY89Q7GS/YqA24ASKnc09cRFsTmU0e/9BCbz9zXO4sJ8GaGHz7AAAAFQDZrJCdxTQ8GVvoFjL9Q1s1VHiClwAAAIBK+6r/kP/9VUzfRepEHCVObTIRYIhC9YcIZe2pMyCQSUIAjkGd5hkA8XQecs5/ym5Ddm2j61Kvt2jtGXQVP2F04wIFDuGK4GAfPpYjvLJaXtVxj1Ho4K2W/+WgKG1NEh466myZNsHr3v1MufbxNIS03lg6s8oJI4TmCaWtVHNW+AAAAIEAqh+ablUfEZAr6" ];
      uid = 1002;
    };

  users.users.homepage =
    { createHome = true;
      description = "nixos.org website";
      group = "users";
      home = "/home/homepage";
      useDefaultShell = true;
      openssh.authorizedKeys.keys = [ sshKeys.eelco sshKeys.rob ];
    };

  systemd.services.update-homepage =
    { description = "Update nixos.org Homepage";
      # FIXME: gnutar/xz deps work around a Nix bug.
      path = [ config.nix.package pkgs.git pkgs.bash pkgs.gnutar pkgs.xz ];
      serviceConfig.User = "homepage";
      environment.NIX_PATH = concatStringsSep ":" config.nix.nixPath;
      environment.NIX_REMOTE = "daemon";
      environment.CURL_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";
      serviceConfig.Type = "oneshot";
      script =
        ''
          cd ~/nixos-homepage
          git pull
          exec nix-shell --command 'make UPDATE=1'
        '';
      startAt = "*:0/20";
    };

  system.activationScripts.setShmMax =
    ''
      ${pkgs.procps}/sbin/sysctl -q -w kernel.shmmax=$((1 * 1024**3))
    '';

  services.venus = {
    enable = true;
    outputTheme = ./theme;
    outputDirectory = "/var/www/planet.nixos.org";
    feeds = import ./planet-feeds.nix;
  };

  nix.gc.automatic = true;

}
