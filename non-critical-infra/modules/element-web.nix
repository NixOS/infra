{ pkgs, ... }:
let
  domainName = "chat.nixos.org";

  # https://github.com/element-hq/element-web/blob/develop/config.sample.json
  elementWebConfig = {
    default_server_config = {
      "m.homeserver" = {
        base_url = "https://matrix.nixos.org";
        server_name = "nixos.org";
      };
      "m.identity_server" = {
        base_url = "https://vector.im";
      };
    };
    disable_custom_urls = false;
    disable_guests = false;
    disable_login_language_selector = false;
    disable_3pid_login = false;
    brand = "Element";
    integrations_ui_url = "https://scalar.vector.im/";
    integrations_rest_url = "https://scalar.vector.im/api";
    integrations_widgets_urls = [
      "https://scalar.vector.im/_matrix/integrations/v1"
      "https://scalar.vector.im/api"
      "https://scalar-staging.vector.im/_matrix/integrations/v1"
      "https://scalar-staging.vector.im/api"
      "https://scalar-staging.riot.im/scalar/api"
    ];
    integrations_jitsi_widget_url = "https://scalar.vector.im/api/widgets/jitsi.html";
    bug_report_endpoint_url = "https://riot.im/bugreports/submit";
    default_country_code = "GB";
    show_labs_settings = true;
    features = { };
    default_federate = true;
    default_theme = "light";
    roomDirectory = {
      servers = [ ];
    };
    settingDefaults = {
      breadcrumbs = true;
    };
    jitsi = {
      preferred_domain = "meet.element.io";
    };
    element_call = {
      url = "https://call.element.io";
      participant_limit = 8;
      brand = "Element Call";
    };
    map_style_url = "https://api.maptiler.com/maps/streets/style.json?key=fU3vlMsMn4Jb6dnEIFsx";
  };
in
{
  security.acme.certs."${domainName}".reloadServices = [ "nginx.service" ];

  services.nginx.virtualHosts."${domainName}" = {
    enableACME = true;
    forceSSL = true;

    root = pkgs.element-web.override (_old: {
      conf = elementWebConfig;
    });
  };
}
