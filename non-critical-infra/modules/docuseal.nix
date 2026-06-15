{ config, ... }:
{
  services.backup.includes = [ "/var/lib/docuseal" ];

  services.docuseal = {
    enable = true;
    extraConfig = {
      SMTP_ADDRESS = "umbriel.nixos.org";
      SMTP_PORT = "465";
      SMTP_ENABLE_STARTTLS = "false"; # We're using port 465, which uses implicit TLS.
      SMTP_FROM = "docuseal-noreply@nixos.org";
      SMTP_USERNAME = "docuseal-noreply@nixos.org";
      SMTP_ENABLE_TLS = "true";
    };
    extraEnvFiles = [ config.sops.templates."docuseal.env".path ];
  };

  # How to generate:
  #
  #   $ cd non-critical-infra
  #   $ SECRET_PATH=secrets/docuseal-secret-key-base.caliban
  #   $ openssl rand -hex 64 | tr -d '\n' > "$SECRET_PATH"
  #   $ sops encrypt --in-place "$SECRET_PATH"
  sops.secrets.docuseal-secret-key-base = {
    sopsFile = ../secrets/docuseal-secret-key-base.caliban;
    format = "binary";
    restartUnits = [ config.systemd.services.docuseal.name ];
  };

  sops.secrets.docuseal-smtp-password = {
    # Keep this in sync with <../secrets/docuseal-noreply-email-login.umbriel>.
    sopsFile = ../secrets/docuseal-noreply-email-login.caliban;
    format = "binary";
    restartUnits = [ config.systemd.services.docuseal.name ];
  };

  sops.templates."docuseal.env".content = ''
    SMTP_PASSWORD=${config.sops.placeholder.docuseal-smtp-password}
  '';

  services.docuseal.secretKeyBaseFile = "/run/credentials/${config.systemd.services.docuseal.name}/secret-key-base";

  systemd.services.docuseal.serviceConfig = {
    LoadCredential = "secret-key-base:${config.sops.secrets.docuseal-secret-key-base.path}";
  };

  services.nginx.virtualHosts."docuseal.nixos.org" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.docuseal.port}";
      proxyWebsockets = true;
    };
  };
}
