{ config
, pkgs
, ...
}:

{
  imports = [
    ./nginx.nix
    ./postgresql.nix
  ];

  fileSystems."/var/lib/matrix-synapse" = {
    device = "zroot/root/matrix-synapse";
    fsType = "zfs";
    options = [
      "zfsutil"
    ];
  };

  services.postgresql = {
    ensureUsers = [ {
      name = "matrix-synapse";
      ensureDBOwnership = true;
    } ];
    # Insufficient to create the database with the correct collation
    # https://github.com/element-hq/synapse/blob/develop/docs/postgres.md#set-up-database
    ensureDatabases = [
      "matrix-synapse"
    ];
  };

  services.postgresqlBackup.databases = [
    "matrix-synapse"
  ];

  services.redis.servers.matrix-synapse = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    matrix-synapse-tools.synadm
  ];

  services.backup.includesZfsDatasets = [
    "/var/lib/matrix-synapse"
  ];

  sops.secrets.matrix-synapse-signing-key = {
    sopsFile = ../secrets/matrix-synapse-signing-key.caliban;
    format = "binary";
    path = "/var/lib/matrix-synapse/nixos.org.signing.key";
    mode = "0600";
    owner = "matrix-synapse";
    group = "matrix-synapse";
  };

  sops.secrets.matrix-synapse-secrets = {
    sopsFile = ../secrets/matrix-synapse-secrets.caliban;
    format = "binary";
    path = "/var/keys/matrix-synapse-secrets.conf";
    mode = "0600";
    owner = "matrix-synapse";
    group = "matrix-synapse";
  };

  systemd.services.matrix-synapse.serviceConfig.SupplementaryGroups = [
    "redis-matrix-synapse"
  ];

  #systemd.services.matrix-synapse.enable = false;

  services.matrix-synapse = {
    enable = true;
    withJemalloc = true;

    extraConfigFiles = [
      config.sops.secrets.matrix-synapse-secrets.path
    ];

    # https://github.com/element-hq/synapse/blob/master/docs/usage/configuration/config_documentation.md
    settings = {
      enable_metrics = true;

      server_name = "nixos.org";
      signing_key_path = config.sops.secrets.matrix-synapse-signing-key.path;
      public_baseurl = "https://matrix.nixos.org";
      admin_contact = "infra@nixos.org";
      web_client_location = "https://matrix.to/#/#community:nixos.org";

      allow_public_rooms_over_federation = true;
      allow_public_rooms_without_auth = true;

      max_upload_size = "50M";

      media_retention = {
        local_media_lifetime = "90d";
        remote_media_lifetime = "14d";
      };

      database = {
        name = "psycopg2";
        args = {
          host = "/run/postgresql";
        };
      };

      redis = {
        enabled = true;
        path = config.services.redis.servers.matrix-synapse.unixSocket;
      };

      listeners = [ {
        type = "http";
        # TODO: migrate to UNIX domain socket
        #path = "/run/matrix-synapse/matrix-synapse.sock";
        #mode = "0660";
        port = 8008;
        tls = false;
        resources = [ {
          compress = true;
          names = [
            "client"
          ];
        } {
          compress = false;
          names = [
            "federation"
          ];
        } ];
      } {
        type = "http";
        bind_addresses = [
          "127.0.0.1"
          "::1"
        ];
        port = 8090;
        tls = false;
        resources = [ {
          names = [
            "metrics"
          ];
        } ];
      } ];
    };
  };

  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "matrix-synapse" ];

  services.nginx = {
    clientMaxBodySize = config.services.matrix-synapse.settings.max_upload_size;
    upstreams."matrix-synapse".servers = {
      # TODO: migrate to UNIX domain socket
      #"unix:/run/matrix-synapse/matrix-synapse.sock" = {};
      "localhost:8008" = {};
    }; 
    virtualHosts."matrix.nixos.org" = {
      forceSSL = true;
      enableACME = true;

      locations."~* ^(\/_matrix|\/_synapse)" = {
        proxyPass = "http://matrix-synapse";
      };
      locations."= /metrics" = {
        proxyPass = "http://localhost:8090/_synapse/metrics";
      };
      locations."= /" = {
        return = "301 https://matrix.to/#/#community:nixos.org";
      };
    };
  };
}
