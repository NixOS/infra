{
  config,
  lib,
  ...
}:

{
  services.prometheus = {
    alertmanagers = [
      {
        scheme = "http";
        static_configs = [
          { targets = [ "localhost:${toString config.services.prometheus.alertmanager.port}" ]; }
        ];
      }
    ];

    alertmanager = {
      enable = true;

      # Allow alertmanager to start even if it doesn't find an RFC1918 IP on
      # the machine's network interfaces.
      extraFlags = [ "--cluster.listen-address=''" ];

      webExternalUrl = "http://alerts.nixos.org";
      configuration = {
        global = { };
        route = {
          receiver = "ignore";
          group_wait = "30s";
          group_interval = "5m";
          repeat_interval = "24h";
          group_by = [ "alertname" ];

          routes = [
            {
              receiver = "matrix";
              group_wait = "30s";
              match.severity = "warning";
            }
          ];
        };
        receivers = [
          {
            # with no *_config, this will drop all alerts directed to it
            name = "ignore";
          }
          {
            name = "matrix";
            webhook_configs = [
              {
                url = "http://localhost:${toString config.services.matrix-alertmanager.port}/alerts";
                send_resolved = true;
                http_config.basic_auth = {
                  username = "alertmanager";
                  password_file = config.age.secrets."matrix-alertmanager-secret".path;
                };
              }
            ];
          }
        ];
      };
    };
  };

  services.nginx.virtualHosts."alerts.nixos.org" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://localhost:9093";
    };
  };

  age.secrets."alertmanager-oauth2-proxy-env".file = ../../secrets/alertmanager-oauth2-proxy-env.age;

  services.oauth2-proxy = {
    enable = true;

    # oidc provider
    provider = "github";
    clientID = "Ov23liDt1q76okEJpVVE";
    keyFile = config.age.secrets."alertmanager-oauth2-proxy-env".path;

    # filter criteria
    email.domains = [ "*" ];
    github = {
      org = "NixOS";
      team = "infra";
    };

    # protected domains
    nginx = {
      domain = "alerts.nixos.org";
      virtualHosts."alerts.nixos.org" = { };
    };
  };

  # access token
  age.secrets."matrix-alertmanager-token".file = ../../secrets/matrix-alertmanager-token.age;
  # webhook secret
  age.secrets."matrix-alertmanager-secret" = {
    file = ../../secrets/matrix-alertmanager-secret.age;
    owner = "alertmanager";
  };

  services.matrix-alertmanager = {
    enable = true;
    tokenFile = config.age.secrets.matrix-alertmanager-token.path;
    secretFile = config.age.secrets.matrix-alertmanager-secret.path;
    homeserverUrl = "https://matrix.nixos.org";
    matrixUser = "@bot:nixos.org";
    matrixRooms = [
      {
        receivers = [ "matrix" ];
        roomId = "!QLQqibtFaVtDgurUAE:nixos.org";
      }
    ];
  };

  systemd.services.matrix-alertmanager.environment = {
    ALERT_LINKS = lib.concatStringsSep "|" [
      "📈 Grafana:{annotations.grafana}"
      "🔥 Prometheus:{generatorURL}"
      "🔕 Silence:https://alerts.nixos.org/#/silences/new?filter={labels.alertname}"
    ];
  };
}
