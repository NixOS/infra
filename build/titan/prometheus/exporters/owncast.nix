{ config, ... }:

{
  age.secrets.owncast-admin-password = {
    file = ../../../secrets/owncast-admin-password.age;
    owner = "prometheus";
    group = "prometheus";
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "owncast";
      metrics_path = "/api/admin/prometheus";
      basic_auth = {
        username = "admin";
        password_file = config.age.secrets.owncast-admin-password.path;
      };
      scheme = "https";
      static_configs = [ { targets = [ "live.nixos.org:443" ]; } ];
    }
  ];
}
