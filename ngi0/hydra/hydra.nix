{ config, pkgs, ... }:

let
  narCache = "/var/cache/hydra/nar-cache";
in

{
  services.hydra-dev.enable = true;
  services.hydra-dev.logo = ./ngi-logo.svg;
  services.hydra-dev.hydraURL = "https://hydra.ngi0.nixos.org";
  services.hydra-dev.notificationSender = "ngi@nixos.org";
  services.hydra-dev.smtpHost = "localhost";
  services.hydra-dev.useSubstitutes = true;
  services.hydra-dev.extraConfig =
    ''
      max_servers 15

      enable_google_login = 1
      google_client_id = 816926039128-splu8iepg00ntgp9ngm6ic6fu8uenuir.apps.googleusercontent.com

      store_uri = s3://ngi0-cache?secret-key=/var/lib/hydra/queue-runner/keys/cache.ngi0.nixos.org-1/secret&write-nar-listing=1&ls-compression=br&log-compression=br&region=eu-west-1
      server_store_uri = https://cache.ngi0.nixos.org?local-nar-cache=${narCache}
      binary_cache_public_uri = https://cache.ngi0.nixos.org

      <Plugin::Session>
        cache_size = 32m
      </Plugin::Session>

      # patchelf:master:3
      xxx-jobset-repeats = nixos:reproducibility:1

      # https://status.nixos.org/prometheus/graph?g0.range_input=2w&g0.expr=hydra_memory_tokens_in_use&g0.tab=0
      nar_buffer_size = ${let gb = 8; in toString (gb * 1024 * 1024 * 1024)}

      #upload_logs_to_binary_cache = true

      # FIXME: Cloudfront messes up CORS
      #log_prefix = https://cache.ngi0.nixos.org/

      log_prefix = https://ngi0-cache.s3.eu-west-1.amazonaws.com/

      evaluator_workers = 4
      evaluator_max_memory_size = 4096

      max_concurrent_evals = 2
    '';
}