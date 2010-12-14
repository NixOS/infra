# JIRA server.

{ config, pkgs, modulesPath, ... }:

with pkgs.lib;

let

  jiraJetty = (import ../../services/jira/jira-instance.nix {
    inherit pkgs;
    dbHost = "192.168.1.25";
    dbPassword = import ./jira-password.nix;
  }).jetty;

in

{
  require = [ "${modulesPath}/virtualisation/xen-domU.nix" ./common.nix ];

  nixpkgs.system = "x86_64-linux";

  networking.hostName = "mrkitty";

  fileSystems = 
    [ { mountPoint = "/";
        label = "nixos";
      }
    ];

  services.sshd.enable = true;

  users.extraUsers = singleton
    { name = "jira";
      description = "JIRA bug tracker";
    };

  jobs.jira =
    { description = "JIRA bug tracker";

      startOn = "started network-interfaces";

      preStart =
        ''
          mkdir -p /var/log/jetty /var/cache/jira /var/cache/jira/issues
          chown jira /var/log/jetty /var/cache/jira /var/cache/jira/issues
        '';

      exec = "${pkgs.su}/bin/su -s ${pkgs.bash}/bin/sh jira -c '${jiraJetty}/bin/run-jetty'";

      postStop =
        ''
          ${pkgs.su}/bin/su -s ${pkgs.bash}/bin/sh jira -c '${jiraJetty}/bin/stop-jetty'
        '';
    };
}
