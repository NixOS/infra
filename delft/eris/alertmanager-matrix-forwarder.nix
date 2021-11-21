{ config, pkgs, ... }:
let
  finalConfigFile = "/var/run/go-neb/config.yaml";

  settingsFormat = pkgs.formats.yaml {};
  configFile = settingsFormat.generate "config.yaml" config.services.go-neb.config;

  go-neb = pkgs.callPackage ./go-neb-backport.nix {};
in {
  deployment.keys."alertmanager-matrix-forwarder" = {
    keyFile = /home/deploy/src/nixos-org-configurations/keys/alertmanager-matrix-forwarder;
    # user = config.systemd.services.go-neb.serviceConfig.User;
  };

  systemd.services.go-neb = {
    serviceConfig = {
      ExecStartPre = pkgs.writeShellScript "pre-start" ''
        umask 077
        export $(xargs < /run/keys/alertmanager-matrix-forwarder)
        ${pkgs.envsubst}/bin/envsubst -i "${configFile}" > ${finalConfigFile}
        chown go-neb ${finalConfigFile}
      '';
      ExecStart = pkgs.lib.mkForce "${go-neb}/bin/go-neb";
      User = "go-neb";
      SupplementaryGroups = [ "keys" ];
      RuntimeDirectory = "go-neb";
      PermissionsStartOnly = true;
    };
    environment.CONFIG_FILE = pkgs.lib.mkForce finalConfigFile;
  };

  services.go-neb = {
    enable = true;
    baseUrl = "http://localhost";
    config = {
      clients = [
        { UserId = "@bot:nixos.org";
          AccessToken = "$CHANGEME";
          HomeServerUrl = "https://nixos.ems.host";
          Sync = true;
          AutoJoinRooms = true;
          DisplayName = "Bot";
        }
      ];
      services = [
        { ID = "alertmanager_service";
          Type = "alertmanager";
          UserId = "@bot:nixos.org";
          Config = {
            webhook_url = "http://localhost:5040/services/hooks/YWxlcnRtYW5hZ2VyX3NlcnZpY2UK";
            rooms = {
              "!QLQqibtFaVtDgurUAE:nixos.org" = { #bots:nixos.org
                text_template = ''
                  {{range .Alerts -}} [{{ .Status }}] {{index .Labels "alertname" }}: {{index .Annotations "description"}} {{ end -}}
                '';

                # $$severity otherwise envsubst replaces $severity with an empty string
                html_template = ''
                  {{range .Alerts -}}
                    {{ $$severity := index .Labels "severity" }}
                    {{ if eq .Status "firing" }}
                      {{ if eq $$severity "critical"}}
                        <font color='red'><b>[FIRING - CRITICAL]</b></font>
                      {{ else if eq $$severity "warning"}}
                        <font color='orange'><b>[FIRING - WARNING]</b></font>
                      {{ else }}
                        <b>[FIRING - {{ $$severity }}]</b>
                      {{ end }}
                    {{ else }}
                      <font color='green'><b>[RESOLVED]</b></font>
                    {{ end }}
                    {{ index .Labels "alertname"}}: {{ index .Annotations "summary"}} (<a href="{{ .GeneratorURL }}">source</a>, <a href="{{ .SilenceURL }}">silence</a>)<br/>
                  {{end -}}'';
                msg_type = "m.text"; # Must be either `m.text` or `m.notice`
              };
            };
          };
        }
      ];
    };
  };
}
