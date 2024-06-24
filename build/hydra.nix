{ lib, pkgs, ... }:

with lib;

let
  narCache = "/var/cache/hydra/nar-cache";
in

{
  services.hydra-dev.enable = true;
  services.hydra-dev.logo = ./hydra-logo.png;
  services.hydra-dev.hydraURL = "https://hydra.nixos.org";
  services.hydra-dev.notificationSender = "edolstra@gmail.com";
  services.hydra-dev.smtpHost = "localhost";
  services.hydra-dev.useSubstitutes = false;
  services.hydra-dev.extraConfig =
    ''
      max_servers 30

      enable_google_login = 1
      google_client_id = 816926039128-ia4s4rsqrq998rsevce7i09mo6a4nffg.apps.googleusercontent.com

      github_client_id = b022c64ce4531ffc1031
      github_client_secret_file = /var/lib/hydra/www/keys/hydra-github-client-secret

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

      max_unsupported_time = 86400

      allow_import_from_derivation = false
      
      max_output_size = 3221225472 # 3 << 30 = 3 GB
      max_db_connections = 350

      queue_runner_metrics_address = [::]:9198

      <hydra_notify>
        <prometheus>
          listen_address = 0.0.0.0
          port = 9199
        </prometheus>
      </hydra_notify>
    '';

  # Work around https://github.com/NixOS/hydra/issues/1337
  services.hydra-dev.package = pkgs.hydra.overrideAttrs(_: prev: {
    postPatch = ''
      ${prev.postPatch or ""}
      rm src/lib/Hydra/Plugin/DeclarativeJobsets.pm
      rm t/Hydra/Plugin/DeclarativeJobsets/basic.t
    '';
  });

  systemd.tmpfiles.rules =
    [
      "d /var/cache/hydra 0755 hydra hydra -  -"
      "d ${narCache}      0775 hydra hydra 1d -"
    ];

  # users.extraUsers.hydra.home = mkForce "/home/hydra";

  systemd.services.hydra-queue-runner.restartIfChanged = false;
  systemd.services.hydra-queue-runner.wantedBy = mkForce [ ];
  systemd.services.hydra-queue-runner.requires = mkForce [ ];
  systemd.services.hydra-queue-runner.serviceConfig.LimitNOFILE = 65535;

  programs.ssh.hostKeyAlgorithms = [ "rsa-sha2-512-cert-v01@openssh.com" "ssh-ed25519" "ssh-rsa" "ecdsa-sha2-nistp256" ];
  programs.ssh.extraConfig = mkAfter
    ''
      ServerAliveInterval 120
      TCPKeepAlive yes
      
      Host mac-m1-1
      Hostname 10.254.2.101
      Compression yes

      Host mac-m1-2
      Hostname 10.254.2.102
      Compression yes

      Host mac-m1-3
      Hostname 10.254.2.103
      Compression yes

      Host mac-m1-4
      Hostname 10.254.2.104
      Compression yes

      Host mac-m1-5
      Hostname 10.254.2.105
      Compression yes

      Host mac-m1-6
      Hostname 10.254.2.106
      Compression yes

      Host macstadium-x86-44911507
      Hostname 208.83.1.186
      Compression yes

      Host macstadium-x86-44911362
      Hostname 208.83.1.175
      Compression yes

      Host macstadium-x86-44911305
      Hostname 208.83.1.173
      Compression yes

      Host macstadium-m1-44911104
      Hostname 208.83.1.181
      Compression yes

      Host macstadium-m1-44911207
      Hostname 208.83.1.145
      Compression yes
    '';

  services.openssh.knownHosts = {
    "*.cloudscalehydra.detsys.dev" = { certAuthority = true; publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC6HhovazfX+rqm2YuOwgM1X16Z7bJpLLj4DXWUsuGGqG/OlwIyioVodKPd3dYwsltQD8W4YrWQCOXlqyV50xpngKJX6OXdDt0IWwwgHdW0bT/l+4Yd/B57PbSnXGKLwa7slBwMCGkxpivMwnkQm+1zfQEdVNX5UPiH6xwZSwgsaRHCpumpVUrLNWlWxI5+g3alez/mfp29bgSvMdnIu72Ykb8u0uKOvGVQY7UD9sVU00NSQ16m+NhvvFvVomIF6OXMinBkATuSsoa4jOIg4UTsS5mo8Up8RdZ1qyzxvqf874osn5sYkMVnRZ5G/0bmwdwyYs7mjKh3agt37Fnaj8obyfVRm9aRlKT+Gwc5U2XZF/AdhOq+TdRL2HgaNYwJspHYUQ2jm5YilOgcEfTOgunxDfMIGueqnM6nZoGe7EHA6affr8QLrOXEUVA9uwIMInpLWiDZXk74owDGhIpg8WBpWch+x3SqaLDwLlUYDseJR0BdH9al+UZW1eBinAiEVl6H7KzVLpLqYss38CWT9c7Cq/gltUuwIqgziXFCR4skXfpN5Ozg0Sr9OmkJbxHjGdOmMVT0VKC05KsUEkWW9J18WX3uN1O3Mqu7vWgK9VOqbsnsknP0oBSznniFZYblK0vRgcrKPMAGTZ7RMdTBbys28sj3HKY/CQPv08KV0xgOJQ=="; };

    mac-m1-1 = { hostNames = [ "10.254.2.101" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILIpNE/evvR5mVLslm4G5AV6pQ2wdpIl7FPGDh5wZPLF"; };
    mac-m1-2 = { hostNames = [ "10.254.2.102" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDyGCqoDh+BWnV1NIV2ucyb0WsXz5fH2hKDgC1dhN+Wq"; };
    mac-m1-3 = { hostNames = [ "10.254.2.103" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGtPVTcBWTENjQ3e9ry7pOTFHk316Ahm3VW1Ys0cMhVf"; };
    mac-m1-4 = { hostNames = [ "10.254.2.104" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk2OLBHfCV3yxXzAsgX0r9cQ3KvpESak6s+tYGJq6J4"; };
    mac-m1-5 = { hostNames = [ "10.254.2.105" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHbYjdeghSNg7bU/ER/pTSGwP7Fyd7+OteD06dP4gCfP"; };
    mac-m1-6 = { hostNames = [ "10.254.2.106" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8B5Ek8GhWCO5Qahl20CHn/txxvAweupuIbFmuLjciG"; };

    # These IPs and SSH public keys are specifically provisioned for Hydra
    "intense-heron.mac.nixos.org" = { hostNames = [ "intense-heron.mac.nixos.org" "23.88.75.215" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMXOk44SDOmkZNtOcviM5LIA6yVOmEclPRQTqndvIxyU"; };
    "sweeping-filly.mac.nixos.org" = { hostNames = [ "sweeping-filly.mac.nixos.org" "142.132.141.35" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+kukRUsxSBsW5xITI65pAixwoWx4b6LtASRzFqM2xX"; };
    "maximum-snail.mac.nixos.org" = { hostNames = [ "maximum-snail.mac.nixos.org" "23.88.76.161" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH6Y9cfoJ+6TNS1EbE3OUocnyUtnTtJ0fJybK2+gyVmN"; };
    "growing-jennet.mac.nixos.org" = { hostNames = [ "growing-jennet.mac.nixos.org" "23.88.76.75" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEIUYnFY0tnASbzZOHruwj3n4nX5gT0Zco2Xjv7frINn"; };
    "enormous-catfish.mac.nixos.org" = { hostNames = [ "enormous-catfish.mac.nixos.org" "142.132.140.199" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEevWFDXtUmbaZYiOmPL4uZVXVdHfQ2fMAMGunfDAAT"; };

    t2m = { hostNames = [ "t2m.cunat.cz" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBP9351NRVeQYvNV1bBbC5MX0iSmrXhVcBYMcn6AMo11U2zlOYRqBPzGLPjz9u31t4FxHNovxCrkFTqJY9zbsmTs="; };
    t2a = { hostNames = [ "t2a.cunat.cz" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIu3itg4hn5e4KrnyoreAUN3RIbAcvqc7yWx5i6EWqAu"; };
    t4b = { hostNames = [ "t4b.cunat.cz" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/jE8c0lkc/DlK3R7A+zBr6j/lfEQrhqSD/YOEVs8za"; };

  };

}
