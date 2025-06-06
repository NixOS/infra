{
  config,
  ...
}:
{
  sops.secrets.mjolnir-access-token = {
    sopsFile = ../secrets/mjolnir-access-token.caliban;
    format = "binary";
    restartUnits = [ "draupnir.service" ];
  };

  services.draupnir = {
    enable = true;
    secrets = {
      accessToken = config.sops.secrets.mjolnir-access-token.path;
    };
    settings = {
      # https://github.com/the-draupnir-project/Draupnir/blob/main/config/default.yaml
      homeserverUrl = "https://matrix.nixos.org";
      managementRoom = "#draupnir:nixos.org";
      backgroundDelayMS = "10"; # snappy reactions, we don't mind the performance hit
      protectAllJoinedRooms = true;
      automaticallyRedactForReasons = [
        "spam"
      ];
      web = {
        enabled = true;
        address = "127.0.0.1";
        port = 8082;
        abuseReporting.enabled = true;
      };
      displayReports = true;
    };
  };

  services.nginx.virtualHosts."matrix.nixos.org" = {
    # https://github.com/the-draupnir-project/Draupnir/blob/main/test/nginx.conf
    locations = {
      "~ ^/_matrix/client/(r0|v3)/rooms/([^/\\s]+)/report/(.*)$" = {
        extraConfig = ''
          mirror /report_mirror;

          # Abuse reports should be sent to Draupnir.
          # The r0 endpoint is deprecated but still used by many clients.
          # As of this writing, the v3 endpoint is the up-to-date version.

          # Alias the regexps, to ensure that they're not rewritten.
          set $room_id $2;
          set $event_id $3;
        '';
        proxyPass =
          with config.services.draupnir.settings.web;
          "http://${address}:${toString port}/api/1/report/$room_id/$event_id";
      };
      "/report_mirror" = {
        proxyPass = "http://matrix-synapse$request_uri";
        extraConfig = ''
          internal;
        '';
      };
    };
  };
}
