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
    ensureDatabases = [
      "matrix-synapse"
    ];
  };

  services.redis.servers.matrix-synapse = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    matrix-synapse-tools.synadm
  ];

  services.backup = {
    preHook = ''
      ${config.boot.zfs.package}/bin/zfs snapshot -r ${config.fileSystems."/var/lib/matrix-synapse".device}@backup
    '';
    includes = [
      "/var/lib/matrix-synapse/.snapshot/backup"
    ];
    postHook = ''
      ${config.boot.zfs.package}/bin/zfs destroy -r ${config.fileSystems."/var/lib/matrix-synapse".device}@backup
    '';
  };

  services.matrix-synapse = {
    enable = true;
    withJemalloc = true;

    # https://github.com/element-hq/synapse/blob/master/docs/usage/configuration/config_documentation.md
    settings = {
      enable_metrics = true;

      server_name = "nixos.org";
      public_baseurl = "https://matrix.nixos.org";
      admin_contact = "infra@nixos.org";

      allow_public_rooms_over_federation = true;
      allow_public_rooms_without_auth = true;

      max_upload_size = "50M";

      database = {
        name = "psycopg2";
        args = {
          host = "/run/postgresql";
        };
      };

      redis = {
        enabled = true;
        path = config.services.redis.matrix-synapse.path;
      };

      listeners = [ {
        type = "http";
        path = "/run/matrix-synapse/matrix-synapse.sock";
        mode = "0660";
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
      "unix:/run/matrix-synapse/matrix-synapse.sock" = {};
    }; 
    virtualHosts."matrix.nixos.org" = {
      forceSSL = true;
      enableACME = true;

      locations."^(/_matrix|/_synapse/client)" = {
        proxyPass = "http://matrix-synapse";
      };
      locations."= /metrics" = {
        proxyPass = "http://localhost:8090/_synapse/metrics";
      };
    };
  };
}
