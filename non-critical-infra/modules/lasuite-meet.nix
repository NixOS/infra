{
  config,
  ...
}:
{
  sops.secrets = {
    lasuite-django-secret = {
      sopsFile = ../secrets/lasuite-django-secret.caliban;
      format = "binary";
      restartUnits = [ "lasuite.service" ];
    };
    #TODO: find out
    lasuite-livekit = {
      sopsFile = ../secrets/lasuite-livekit.caliban;
      format = "binary";
      restartUnits = [ "lasuite.service" ];
    };
  };

  services.lasuite-meet = {
    enable = true;
    domain = "lasuite-meet.nixos.org";
    secretKeyPath = config.sops.secrets.lasuite-django-secret.path;

    livekit = {
      enable = true;
      keyFile = config.sops.secrets.lasuite-livekit.path;
    };

    # Databases
    postgresql.createLocally = true;
    redis.createLocally = true;

    settings = {
      LIVEKIT_API_URL = "https://${config.services.lasuite-meet.domain}/livekit";
      LIVEKIT_API_KEY = config.sops.secrets.lasuite-livekit.name;

      FRONTEND_IS_SILENT_LOGIN_ENABLED = true;
    };
  };

  services.nginx.virtualHosts."lasuite-meet" = {
    enableACME = true;
    forceSSL = true;
  };
}
