{
  config,
  lib,
  pkgs,
  ...
}:

let
  narCache = "/var/cache/hydra/nar-cache";
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

  systemd.services.hydra-prune-build-logs = {
    description = "Clean up old build logs";
    startAt = "weekly";
    serviceConfig = {
      User = "hydra-queue-runner";
      Group = "hydra";
      ExecStart = lib.concatStringsSep " " [
        (lib.getExe pkgs.findutils)
        "/var/lib/hydra/build-logs/"
        "-type"
        "f"
        "-mtime"
        "+${toString (3 * 365)}"
        "-delete"
      ];
    };
  };

  # Don't rate-limit the journal.
  services.journald.rateLimitBurst = 0;

  age.secrets.hydra-aws-credentials = {
    file = ./secrets/hydra-aws-credentials.age;
    path = "/var/lib/hydra/queue-runner/.aws/credentials";
    owner = "hydra-queue-runner";
    group = "hydra";
  };

  age.secrets.hydra-github-client-secret = {
    file = ./secrets/hydra-github-client-secret.age;
    owner = "hydra-www";
    group = "hydra";
  };

  services.hydra-dev.enable = true;
  services.hydra-dev.package = pkgs.hydra;
  services.hydra-dev.buildMachinesFiles = [ "/etc/nix/machines" ];
  services.hydra-dev.dbi = "dbi:Pg:dbname=hydra;host=10.254.1.9;user=hydra;";
  services.hydra-dev.logo = ./hydra-logo.png;
  services.hydra-dev.hydraURL = "https://hydra.nixos.org";
  services.hydra-dev.notificationSender = "edolstra@gmail.com";
  services.hydra-dev.smtpHost = "localhost";
  services.hydra-dev.useSubstitutes = false;
  services.hydra-dev.extraConfig = ''
    max_servers 30

    enable_google_login = 1
    google_client_id = 816926039128-ia4s4rsqrq998rsevce7i09mo6a4nffg.apps.googleusercontent.com

    github_client_id = b022c64ce4531ffc1031
    github_client_secret_file = ${config.age.secrets.hydra-github-client-secret.path}

    store_uri = s3://nix-cache?secret-key=/var/lib/hydra/queue-runner/keys/cache.nixos.org-1/secret&write-nar-listing=1&ls-compression=br&log-compression=br
    server_store_uri = https://cache.nixos.org?local-nar-cache=${narCache}
    binary_cache_public_uri = https://cache.nixos.org

    <Plugin::Session>
      cache_size = 32m
    </Plugin::Session>

    # patchelf:master:3
    xxx-jobset-repeats = nixos:reproducibility:1

    upload_logs_to_binary_cache = true
    compress_build_logs = false  # conflicts with upload_logs_to_binary_cache

    log_prefix = https://cache.nixos.org/

    evaluator_workers = 8
    evaluator_max_memory_size = 4096

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

  systemd.tmpfiles.rules = [
    "d /var/cache/hydra 0755 hydra hydra -  -"
    "d ${narCache}      0775 hydra hydra 1d -"
  ];

  # eats memory as if it was free
  systemd.services.hydra-notify.enable = false;

  systemd.services.hydra-queue-runner = {
    # restarting the scheduler is very expensive
    restartIfChanged = false;
    serviceConfig = {
      ManagedOOMPreference = "avoid";
      LimitNOFILE = 65535;
    };
  };

  programs.ssh.hostKeyAlgorithms = [
    "rsa-sha2-512-cert-v01@openssh.com"
    "ssh-ed25519"
    "ssh-rsa"
    "ecdsa-sha2-nistp256"
  ];
  programs.ssh.extraConfig = lib.mkAfter ''
    ServerAliveInterval 120
    TCPKeepAlive yes
  '';

  # These IPs and SSH public keys are specifically provisioned for Hydra
  services.openssh.knownHosts = {
    # x86_64-linux at Hetzner
    "elated-minsky.builder.nixos.org".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIvrJpd3aynfPVGGG/s7MtRFz/S6M4dtqvqKI3Da7O7+";
    "sleepy-brown.builder.nixos.org".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOh4/3m7o6H3J5QG711aJdlSUVvlC8yW6KoqAES3Fy6I";
    # aarch64-linux at Hetzner
    "goofy-hopcroft.builder.nixos.org".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICTJEi+nQNd7hzNYN3cLBK/0JCkmwmyC1I+b5nMI7+dd";

    # M1 Macs in North America
    "*.foundation.detsys.dev" = {
      certAuthority = true;
      publicKey = "@cert-authority *.foundation.detsys.dev ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDBQ55ccEXJHIY9Cde6hSx26zTOju0RIXzuJL2uxmKrSc6l2SsZV3RsejfY3vp4Zhs/UVhk9VBkaiYY6bMg1SW6f9A0fBrPOSSytRwKgW/XCO605bdpNlGC5sKFGQAuOZfhFEeW9mInhjn1Pkz63gINrI3jWEM1mWJMKwLpstC2P0wXX3kWxQutPjIQrGqKP+TRiYdWcy+dWUFItXcBQkBRk+2xC24PL4s5JLGJffx/pNt+WnZqADIEu42WgrQiiz5OPGoGwlzDNgcWltuHdYaDtKU7bDY4wZxWa/HZGNju1vqLbVPai/Fo4EpONjKr4+EJpInxTpmjm4rcXHmCNmf2fEjZvbpXVcocj/NHp0IuusSLfMo3JfUTo6Vo5gyDjEETWDm1y++pWp5aZ0Dss1mJAbkUN/arMqIIj1RcmLFYf7p9Y1mE7axHZL3BFIlsHxAnZle+ouxPUSIstq9GrD1b3rIC03lTqEH0eTikEpoJAU3OIK5Eoi7vuJyDTtd8rzxPhsv3ScxBGJF6BRbyaaBsqjXWphxzlmzKvwH0psLoE3NuS46EQ5VXq4A4p0KgcuybccuxYMDSf81u96LSIm4f7yWZcE7+iXTollc3tn48uxWFSFNLxzo7RixmJ0R/cRPY6KlOUUJyurWO/bMxSc9rxCJpVrrr/0cMbBbEggICEw==";
    };

    # M1 Macs at Hetzner
    "intense-heron.mac.nixos.org".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICeSgOe/cr1yVAJOl30t3AZOLtvzeQa5rnrHGceKeBue";
    "sweeping-filly.mac.nixos.org".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE6b/coXQEcFZW1eG4zFyCMCF0mZFahqmadz6Gk9DWMF";
    "maximum-snail.mac.nixos.org".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEs+fK4hH8UKo+Pa7u1VYltkMufBHHH5uC93RQ2S6Xy9";
    "growing-jennet.mac.nixos.org".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQGthkSSOnhxrIUCMlRQz8FOo5Y5Nk9f9WnVLNeRJpm";
    "enormous-catfish.mac.nixos.org".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlg7NXxeG5L3s0YqSQIsqVG0MTyvyWDHUyYEfFPazLe";

    # M2 Macs at Oakhost
    "kind-lumiere.mac.nixos.org".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFoqn1AAcOqtG65milpBtWVXP5VcBmTUSMGNfJzPwW8Q";
    "eager-heisenberg.mac.nixos.org".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBp9NStfEPu7HdeK8f2KEnynyirjG9BUk+6w2SgJtQyS";

    # vcunat
    "t2a.cunat.cz".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIu3itg4hn5e4KrnyoreAUN3RIbAcvqc7yWx5i6EWqAu";
    "t4b.cunat.cz".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/jE8c0lkc/DlK3R7A+zBr6j/lfEQrhqSD/YOEVs8za";
  };

}
