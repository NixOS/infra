{
  config,
  ...
}:
{
  services.backup.includes = [ "/var/lib/grafana" ];

  age.secrets."grafana-secret-key".file = ../secrets/grafana-secret-key.age;

  services.grafana = {
    enable = true;
    settings = {
      "auth.anonymous".enabled = true;
      users = {
        allow_sign_up = true;
        viewers_can_edit = true;
      };
      server = {
        domain = "grafana.nixos.org";
        root_url = "https://grafana.nixos.org";
        protocol = "socket";
      };
      security.secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";
    };
  };

  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "grafana" ];
}
