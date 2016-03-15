{ config, lib, pkgs, ...}:

{
  imports =
    [ ./common.nix
      ./hydra.nix
      ./hydra-proxy.nix
      ./datadog.nix
      ./fstrim.nix
    ];

  deployment.targetEnv = "hetzner";
  deployment.hetzner.mainIPv4 = "46.4.67.10";

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql95;
    extraConfig = ''
      log_min_duration_statement = 5000
      log_duration = off
      log_statement = 'none'
      max_connections = 250
      work_mem = 16MB
      shared_buffers = 4GB

      # Checkpoint every 256 MB.
      min_wal_size = 128MB
      max_wal_size = 256MB

      # We can risk losing some transactions.
      synchronous_commit = off

      effective_cache_size = 16GB
    '';
  };

  networking = {

    firewall.allowedTCPPorts = [ 80 443 ];
    firewall.allowPing = true;
    firewall.logRefusedConnections = true;

  };

}
