{
  services.backup.includes = [ "/var/lib/grafana" ];

  services.grafana = {
    enable = true;
    settings = {
      "auth.anonymous".enabled = true;
      users.allow_sign_up = true;
      server = {
        domain = "grafana.nixos.org";
        root_url = "https://grafana.nixos.org";
        protocol = "socket";
      };
    };
  };

  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "grafana" ];
}
