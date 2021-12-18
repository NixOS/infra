{ config, pkgs, ... }:
{
  deployment.keys."alertmanager-matrix-forwarder" = {
    keyFile = /home/deploy/src/nixos-org-configurations/keys/alertmanager-matrix-forwarder;
    # user = config.systemd.services.go-neb.serviceConfig.User;
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
            webhook_url = "http://localhost:5040/services/hooks/YWxlcnRtYW5hZ2VyX3NlcnZpY2U";
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
