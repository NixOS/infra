{ pkgs, ... }:
{
  users.extraUsers.alertmanager-notifier = {
    description = "Prometheus Alert Manager to IRC Forwarder";
  };

  deployment.keys."alertmanager-irc-forwarder.env" = {
    keyFile = /home/deploy/src/nixos-org-configurations/keys/alertmanager-irc-forwarder.env;
    user = "alertmanager-notifier";
  };

  systemd.services.prometheus-alertmanager-irc-notifier = {
    wantedBy = [ "multi-user.target" ];

    path = [
      (pkgs.python3.withPackages (p: with p; [
        flask pika
      ]))
    ];
    script = "exec python3 -m flask run --port 9080";

    environment = {
      FLASK_APP = ./prometheus-alertmanager-irc-notifier.py;
      EXTERNAL_URL = "https://monitoring.nixos.org/prometheus/alerts";
    };

    serviceConfig = {
      User = "alertmanager-notifier";
      Group = "keys";
      EnvironmentFile = "/run/keys/alertmanager-irc-forwarder.env";
    };
  };
}
