{ config, ... }:
{
  imports = [
    ./backup.nix
    ./postfix.nix
  ];

  services.vaultwarden = {
    enable = true;
    backupDir = "/var/backup/vaultwarden/";
    environmentFile = "/var/lib/bitwarden_rs/vaultwarden.env";
    config = {
      DOMAIN = "https://vault.nixos.org";
      SIGNUPS_ALLOWED = false;
      SHOW_PASSWORD_HINT = false;
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "critical";
      SMTP_HOST = "localhost";
      SMTP_PORT = 25;
      SMTP_SSL = false;
      SMTP_FROM = "vaultwarden@caliban.nixos.org";
      SMTP_FROM_NAME = "NixOS Vaultwarden";
      ORG_EVENTS_ENABLED = true;
    };
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."vault.nixos.org" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
      };
    };
  };

  sops.secrets = {
    vaultwarden-env = {
      sopsFile = ../secrets/vaultwarden-env.caliban;
      format = "binary";
      path = "/var/lib/bitwarden_rs/vaultwarden.env";
    };

  };

  services.backup.includes = [ config.services.vaultwarden.backupDir ];

  services.fail2ban = {
    enable = true;
    jails = {
      vaultwarden-web = {
        filter = {
          INCLUDES.before = "common.conf";
          Definition = {
            failregex = "^.*Username or password is incorrect\. Try again\. IP: <ADDR>\. Username:.*$";
            ignoreregex = "";
          };
        };
        settings = {
          backend = "systemd";
          port = "80,443";
          filter = "vaultwarden_web[journalmatch='_SYSTEMD_UNIT=vaultwarden.service']";
          banaction = "%(banaction_allports)s";
          maxretry = 3;
          bantime = 14400;
          findtime = 14400;
        };
      };
      vaultwarden-admin = {
        filter = {
          INCLUDES.before = "common.conf";
          Definition = {
            failregex = "^.*Invalid admin token\. IP: <ADDR>.*$";
            ignoreregex = "";
          };
        };
        settings = {
          backend = "systemd";
          port = "80,443";
          filter = "vaultwarden-admin[journalmatch='_SYSTEMD_UNIT=vaultwarden.service']";
          banaction = "%(banaction_allports)s";
          maxretry = 3;
          bantime = 14400;
          findtime = 14400;
        };
      };
    };

  };

}
