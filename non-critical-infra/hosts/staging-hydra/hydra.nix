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

  # gc outputs as well, since they are served from the cache
  nix.settings.gc-keep-outputs = lib.mkForce false;

  # Don't rate-limit the journal.
  services.journald.rateLimitBurst = 0;

  sops.secrets = {
    signing-key = {
      sopsFile = ../../secrets/signing-key.staging-hydra;
      format = "binary";
    };
    hydra-aws-credentials = {
      sopsFile = ../../secrets/hydra-aws-credentials.staging-hydra;
      format = "binary";
    };
  };

  services.hydra-dev = {
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
    useSubstitutes = false;
    extraConfig = ''
      max_servers 30

      store_uri = s3://nixos-cache-staging?secret-key=${config.sops.secrets.signing-key.path}=1&ls-compression=br&log-compression=br
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

      evaluator_workers = 16
      evaluator_max_memory_size = 8192

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

  systemd = {
    tmpfiles.rules = [
      "d /var/cache/hydra 0755 hydra hydra -  -"
      "d ${narCache}      0775 hydra hydra 1d -"
    ];

    # eats memory as if it was free
    services = {
      hydra-notify.enable = false;
      hydra-queue-runner = {
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
