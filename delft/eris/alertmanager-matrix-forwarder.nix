{ config, pkgs, ... }:
{
  deployment.keys."alertmanager-matrix-forwarder" = {
    keyFile = /home/deploy/src/nixos-org-configurations/keys/alertmanager-matrix-forwarder;
    user = config.systemd.services.go-neb.serviceConfig.User;
  };

  # Create user so that we can set the ownership of the key to
  # it. DynamicUser will not take full effect as a result of this.
  users.users.go-neb = {
    isSystemUser = true;
    group = "go-neb";
  };
  users.groups.go-neb = {};

  systemd.services.go-neb.serviceConfig.SupplementaryGroups = [ "keys" ];

  services.go-neb = {
    enable = true;
    baseUrl = "http://localhost";
    secretFile = "/run/keys/alertmanager-matrix-forwarder";
    config = {
      clients = [
        {
          UserId = "@bot:nixos.org";
          AccessToken = "$CHANGEME";
          HomeServerUrl = "https://nixos.ems.host";
          Sync = true;
          AutoJoinRooms = true;
          DisplayName = "Bot";
        }
      ];
      services = [
        {
          ID = "alertmanager_service";
          Type = "alertmanager";
          UserId = "@bot:nixos.org";
          Config = {
            webhook_url = "http://localhost:4050/services/hooks/YWxlcnRtYW5hZ2VyX3NlcnZpY2U";
            rooms = {
              "!QLQqibtFaVtDgurUAE:nixos.org" = {
                #bots:nixos.org
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
                    {{ index .Labels "alertname"}}: {{ index .Annotations "summary"}}
                    (
                      <a href="{{ index .Annotations "grafana" }}">📈 Grafana</a>,
                      <a href="{{ .GeneratorURL }}">🔥 Prometheus</a>,
                      <a href="{{ .SilenceURL }}">🔕 Silence</a>
                    )<br/>
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
