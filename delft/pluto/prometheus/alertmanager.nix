{ config
, ...
}:

{
  networking.firewall.interfaces.wg0.allowedTCPPorts = [
    9093
  ];

  services.prometheus = {
    alertmanagers = [ {
      scheme = "http";
      static_configs = [ {
          targets = [ "localhost:${toString config.services.prometheus.alertmanager.port}" ];
      } ];
    } ];

    alertmanager = {
      enable = true;

      # Allow alertmanager to start even if it doesn't find an RFC1918 IP on
      # the machine's network interfaces.
      extraFlags = [ "--cluster.listen-address=''" ];

      webExternalUrl = "http://10.254.1.4:9093/";
      configuration = {
        global = { };
        route = {
          receiver = "ignore";
          group_wait = "30s";
          group_interval = "5m";
          repeat_interval = "4h";
          group_by = [ "alertname" ];

          routes = [ {
            receiver = "go-neb";
            group_wait = "30s";
            match.severity = "warning";
          } ];
        };
        receivers = [ {
          # with no *_config, this will drop all alerts directed to it
          name = "ignore";
        } {
          name = "go-neb";
          webhook_configs = [ {
            url = "${config.services.go-neb.baseUrl}:4050/services/hooks/YWxlcnRtYW5hZ2VyX3NlcnZpY2U";
            send_resolved = true;
          } ];
        } ];
      };
    };
  };

  age.secrets.alertmanager-matrix-forwarder = {
    file = ../../secrets/alertmanager-matrix-forwarder.age;
    owner = config.systemd.services.go-neb.serviceConfig.User;
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
    secretFile = config.age.secrets.alertmanager-matrix-forwarder.path;
    config = {
      clients = [ {
        UserId = "@bot:nixos.org";
        AccessToken = "$CHANGEME";
        HomeServerUrl = "https://nixos.ems.host";
        Sync = true;
        AutoJoinRooms = true;
        DisplayName = "Bot";
      } ];
      services = [ {
        ID = "alertmanager_service";
        Type = "alertmanager";
        UserId = "@bot:nixos.org";
        Config = {
          webhook_url = "http://localhost:4050/services/hooks/YWxlcnRtYW5hZ2VyX3NlcnZpY2U";
          rooms = {
            # infra-alerts:nixos.org
            "!QLQqibtFaVtDgurUAE:nixos.org" = {
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
      } ];
    };
  };
}
