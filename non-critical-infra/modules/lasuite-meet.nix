{
  config,
  ...
}:
{
  sops.secrets = {
    #TODO: find out
    lasuite-livekit-keyfile = {
      sopsFile = ../secrets/lasuite-livekit-keyfile.caliban;
      format = "yml";
      restartUnits = [ "lasuite.service" ];
    };

  };

  services.lasuite-meet = {
    enable = true;
    enableNginx = true;
    domain = "lasuite-meet.nixos.org";
    livekit = {
      enable = true;
      keyFile = config.sops.secrets.lasuite-livekit-keyfile.path;
    };

    # Databases
    postgresql.createLocally = true;
    redis.createLocally = true;

    settings = {
      FRONTEND_IS_SILENT_LOGIN_ENABLED = true;
      ALLOW_UNREGISTERED_ROOMS = true; # We want to allow for the creation of rooms unregistered in case a maintainer needs to meet with another maintainer or a team needs to create a meeting room.
      RECORDING_ENABLE = true; # Useful for SC for recording mins during meetings.
    };
  };

  # This is still requires as enableNginx doesn't enable the acme and forceSSL.
  services.nginx.virtualHosts."lasuite-meet" = {
    enableACME = true;
    forceSSL = true;
  };
}
