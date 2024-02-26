{
  services.backup.includes = [
    "/var/lib/grafana"
  ];

  services.grafana = {
    enable = true;
    auth.anonymous.enable = true;
    users.allowSignUp = true;
    addr = "0.0.0.0";
    domain = "grafana.nixos.org";
    rootUrl = "https://grafana.nixos.org";
  };
}
