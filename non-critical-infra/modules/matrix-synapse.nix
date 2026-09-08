{ config, pkgs, ... }:

{
  imports = [
    ./nginx.nix
    ./postgresql.nix
  ];

  fileSystems."/var/lib/matrix-synapse" = {
    device = "zroot/root/matrix-synapse";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  services.postgresql = {
    ensureUsers = [
      {
        name = "matrix-synapse";
        ensureDBOwnership = true;
      }
    ];
    # Insufficient to create the database with the correct collation
    # https://github.com/element-hq/synapse/blob/develop/docs/postgres.md#set-up-database
    ensureDatabases = [ "matrix-synapse" ];
  };

  services.postgresqlBackup.databases = [ "matrix-synapse" ];

  services.redis.servers.matrix-synapse = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [ synadm ];

  services.backup.includesZfsDatasets = [ "/var/lib/matrix-synapse" ];

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

  systemd.services.matrix-synapse.serviceConfig.SupplementaryGroups = [ "redis-matrix-synapse" ];

  services.matrix-synapse = {
    enable = true;
    enableRegistrationScript = false; # not compatible with unix sockets
    withJemalloc = true;

    extraConfigFiles = [ config.sops.secrets.matrix-synapse-secrets.path ];

    configureRedisLocally = true;

    workers = {
      client1 = {
        worker_app = "synapse.app.generic_worker";
        worker_listeners = [
          {
            path = "/run/matrix-synapse/client1.sock";
            type = "http";
            x_forwarded = true;
            resources = [
              {
                compress = true;
                names = [
                  "client"
                  "metrics"
                ];
              }
            ];
          }
        ];
      };
      client2 = {
        worker_app = "synapse.app.generic_worker";
        worker_listeners = [
          {
            path = "/run/matrix-synapse/client2.sock";
            type = "http";
            x_forwarded = true;
            resources = [
              {
                compress = true;
                names = [
                  "client"
                  "metrics"
                ];
              }
            ];
          }
        ];
      };
    };

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

      instance_map = {
        main = {
          path = "/run/matrix-synapse/replication.sock";
        };
      };

      listeners = [
        {
          type = "http";
          path = "/run/matrix-synapse/main.sock";
          mode = "0660";
          resources = [
            {
              compress = true;
              names = [
                "client"
                "metrics"
              ];
            }
            {
              compress = false;
              names = [ "federation" ];
            }
          ];
        }
        {
          path = "/run/matrix-synapse/replication.sock";
          type = "http";
          resources = [
            { names = [ "replication" ]; }
          ];
        }
      ];
    };
  };

  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "matrix-synapse" ];

  services.nginx = {
    clientMaxBodySize = config.services.matrix-synapse.settings.max_upload_size;
    upstreams = {
      synapse_main.servers = {
        "unix:/run/matrix-synapse/main.sock" = { };
      };
      synapse_client = {
        servers = {
          "unix:/run/matrix-synapse/client1.sock" = { };
          "unix:/run/matrix-synapse/client2.sock" = { };
        };
      };
      synapse_client1.servers = {
        "unix:/run/matrix-synapse/client1.sock" = { };
      };
      synapse_client2.servers = {
        "unix:/run/matrix-synapse/client2.sock" = { };
      };
    };
    appendHttpConfig = ''
      # Updated for 1.159.0
      # https://github.com/element-hq/synapse/blob/develop/docs/workers.md
      map $request_uri $matrix_backend {
        default synapse_main;

        # Event sending requests
        ~^/_matrix/client/(api/v1|r0|v3|unstable)/rooms/.*/redact synapse_client;
        ~^/_matrix/client/(api/v1|r0|v3|unstable)/rooms/.*/send synapse_client;
        ~^/_matrix/client/(api/v1|r0|v3|unstable)/rooms/.*/state/ synapse_client;
        ~^/_matrix/client/(api/v1|r0|v3|unstable)/rooms/.*/(join|invite|leave|ban|unban|kick)$ synapse_client;
        ~^/_matrix/client/(api/v1|r0|v3|unstable)/join/ synapse_client;
        ~^/_matrix/client/(api/v1|r0|v3|unstable)/knock/ synapse_client;
        ~^/_matrix/client/(api/v1|r0|v3|unstable)/profile/ synapse_client;
      }

      map $uri $metrics_backend {
        default "";
        /metrics/main synapse_main;
        /metrics/client1 synapse_client1;
        /metrics/client2 synapse_client2;
      }
    '';
    virtualHosts."matrix.nixos.org" = {
      forceSSL = true;
      enableACME = true;

      locations."~* ^/_matrix" = {
        proxyPass = "http://$matrix_backend";
      };
      locations."~* ^/_synapse" = {
        proxyPass = "http://synapse_main";
      };
      locations."~ ^/metrics/[^/]+$" = {
        proxyPass = "http://$metrics_backend/_synapse/metrics";
      };
      locations."= /" = {
        return = "301 https://matrix.to/#/#community:nixos.org";
      };
    };
  };
}
