{
  services.backup.includes = [
    "/var/lib/grafana"
  ];

  services.grafana = {
    enable = true;
    auth.anonymous.enable = true;
    users.allowSignUp = true;
    addr = "0.0.0.0";
    domain = "monitoring.nixos.org";
    rootUrl = "https://monitoring.nixos.org/grafana/";
  };
}
