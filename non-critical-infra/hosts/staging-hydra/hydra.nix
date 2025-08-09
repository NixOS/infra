{
  lib,
  pkgs,
  config,
  ...
}:
let
  narCache = "/var/cache/hydra/nar-cache";
  localSystems = [
    "builtin"
    config.nixpkgs.hostPlatform.system
  ];
in
{
  networking.firewall.allowedTCPPorts = [
    9198 # queue-runnner metrics
    9199 # hydra-notify metrics
  ];

  # garbage collection
  nix.gc = {
    automatic = true;
    options = ''--max-freed "$((400 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';
    dates = "03,09,15,21:15";
  };

  nix.settings = {
    # gc outputs as well, since they are served from the cache
    gc-keep-outputs = lib.mkForce false;
    allowed-users = [ "hydra-www" ];
  };

  # Don't rate-limit the journal.
  services.journald.rateLimitBurst = 0;

  sops.secrets = {
    signing-key = {
      sopsFile = ../../secrets/signing-key.staging-hydra;
      format = "binary";
      owner = config.systemd.services.hydra-queue-runner.serviceConfig.User;
    };
    hydra-aws-credentials = {
      sopsFile = ../../secrets/hydra-aws-credentials.staging-hydra;
      format = "binary";
      path = "/var/lib/hydra/queue-runner/.aws/credentials";
      owner = config.systemd.services.hydra-queue-runner.serviceConfig.User;
    };
  };

  services = {
    hydra-dev = {
      enable = true;
      package = pkgs.hydra;
      buildMachinesFiles = [
        (pkgs.writeText "local" ''
          localhost ${lib.concatStringsSep "," localSystems} - 3 1 ${lib.concatStringsSep "," config.nix.settings.system-features} - -
        '')
      ];
      logo = ../../../build/hydra-logo.png;
      hydraURL = "https://hydra.nixos.org";
      notificationSender = "edolstra@gmail.com";
      smtpHost = "localhost";
      useSubstitutes = true;
      extraConfig = ''
        max_servers 30

        store_uri = s3://nix-cache-staging?secret-key=${config.sops.secrets.signing-key.path}&ls-compression=br&log-compression=br
        server_store_uri = https://cache-staging.nixos.org?local-nar-cache=${narCache}
        binary_cache_public_uri = https://cache-staging.nixos.org

        <Plugin::Session>
          cache_size = 32m
        </Plugin::Session>

        # patchelf:master:3
        xxx-jobset-repeats = nixos:reproducibility:1

        upload_logs_to_binary_cache = true
        compress_build_logs = false  # conflicts with upload_logs_to_binary_cache

        log_prefix = https://cache.nixos.org/

        evaluator_workers = 1
        evaluator_max_memory_size = 4096

        queue_runner_endpoint = http://localhost:8080

        max_concurrent_evals = 1

        # increase the number of active compress slots (CPU is 48*2 on mimas)
        max_local_worker_threads = 144

        max_unsupported_time = 86400

        allow_import_from_derivation = false

        max_output_size = 3821225472 # 3 << 30 + 600000000 = 3 GiB + 0.6 GB
        max_db_connections = 350

        queue_runner_metrics_address = [::]:9198

        <hydra_notify>
          <prometheus>
            listen_address = 0.0.0.0
            port = 9199
          </prometheus>
        </hydra_notify>
      '';
    };

    hydra-queue-runner-v2 = {
      enable = true;
      settings.remoteStoreAddr = [
        "s3://nix-cache-staging?secret-key=${config.sops.secrets.signing-key.path}&ls-compression=br&log-compression=br"
      ];
    };

    hydra-queue-builder-v2 = {
      enable = true;
      queueRunnerAddr = "https://queue-runner.staging-hydra.nixos.org";
      mtls = {
        serverRootCaCertPath = "${./ca.crt}";
        clientCertPath = "${./client.crt}";
        clientKeyPath = config.sops.secrets."queue-runner-client.key".path;
        domainName = "queue-runner.staging-hydra.nixos.org";
      };
    };

    nginx = {
      enable = true;
      virtualHosts."queue-runner.staging-hydra.nixos.org" = {
        extraConfig = ''
          ssl_client_certificate ${./ca.crt};
          ssl_verify_depth 2;
          ssl_verify_client on;
        '';

        sslCertificate = ./server.crt;
        sslCertificateKey = config.sops.secrets."queue-runner-server.key".path;
        onlySSL = true;

        locations."/".extraConfig = ''
          # This is necessary so that grpc connections do not get closed early
          # see https://stackoverflow.com/a/67805465
          client_body_timeout 31536000s;

          grpc_pass grpc://[::1]:50051;

          grpc_read_timeout 31536000s; # 1 year in seconds
          grpc_send_timeout 31536000s; # 1 year in seconds
          grpc_socket_keepalive on;

          grpc_set_header Host $host;
          grpc_set_header X-Real-IP $remote_addr;
          grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          grpc_set_header X-Forwarded-Proto $scheme;

          grpc_set_header X-Client-DN $ssl_client_s_dn;
          grpc_set_header X-Client-Cert $ssl_client_escaped_cert;
        '';
      };
    };
  };

  sops.secrets = {
    "queue-runner-server.key" = {
      sopsFile = ../../secrets/queue-runner-server.key.staging-hydra;
      format = "binary";
      owner = config.systemd.services.hydra-queue-runner.serviceConfig.User;
    };
    "queue-runner-client.key" = {
      sopsFile = ../../secrets/queue-runner-client.key.staging-hydra;
      format = "binary";
      owner = config.systemd.services.hydra-queue-runner.serviceConfig.User;
    };
    hydra-users = {
      sopsFile = ../../secrets/hydra-users.staging-hydra;
      format = "binary";
    };
  };

  systemd = {
    tmpfiles.rules = [
      "d /var/cache/hydra 0755 hydra hydra -  -"
      "d ${narCache}      0775 hydra hydra 1d -"
    ];

    # eats memory as if it was free
    services = {
      hydra-notify.enable = false;
      hydra-queue-runner = {
        enable = false;

        # restarting the scheduler is very expensive
        restartIfChanged = false;
        serviceConfig = {
          ManagedOOMPreference = "avoid";
          LimitNOFILE = 65535;
        };
      };

      hydra-prune-build-logs = {
        description = "Clean up old build logs";
        startAt = "weekly";
        serviceConfig = {
          User = "hydra-queue-runner";
          Group = "hydra";
          ExecStart = lib.concatStringsSep " " [
            (lib.getExe pkgs.findutils)
            "/var/lib/hydra/build-logs/"
            "-ignore_readdir_race"
            "-type"
            "f"
            "-mtime"
            "+${toString (3 * 365)}" # days
            "-delete"
          ];
        };
      };
      hydra-post-init = {
        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = "60";
        };
        wantedBy = [ config.systemd.targets.multi-user.name ];
        after = [ config.systemd.services.hydra-server.name ];
        requires = [ config.systemd.services.hydra-server.name ];
        environment = {
          inherit (config.systemd.services.hydra-init.environment) HYDRA_DBI;
        };
        path = [
          config.services.hydra.package
          pkgs.netcat
        ];
        script = ''
          set -e
          while IFS=';' read -r user role passwordhash email fullname; do
            opts=("$user" "--role" "$role" "--password-hash" "$passwordhash")
            if [[ -n "$email" ]]; then
              opts+=("--email-address" "$email")
            fi
            if [[ -n "$fullname" ]]; then
              opts+=("--full-name" "$fullname")
            fi
            hydra-create-user "''${opts[@]}"
          done < ${config.sops.secrets.hydra-users.path}
        '';
      };
    };
  };

  programs.ssh = {
    hostKeyAlgorithms = [
      "rsa-sha2-512-cert-v01@openssh.com"
      "ssh-ed25519"
      "ssh-rsa"
      "ecdsa-sha2-nistp256"
    ];

    extraConfig = lib.mkAfter ''
      ServerAliveInterval 120
      TCPKeepAlive yes
    '';
  };
}
