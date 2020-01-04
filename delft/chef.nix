{ config, lib, pkgs, ...}:

{
  imports =
    [ ./common.nix
      ./datadog.nix
      ./fstrim.nix
    ];

  deployment.targetEnv = "hetzner";
  deployment.hetzner.mainIPv4 = "46.4.67.10";

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql95;
    extraConfig = ''
      listen_addresses = '10.254.1.2'

      log_min_duration_statement = 5000
      log_duration = off
      log_statement = 'none'
      max_connections = 250
      work_mem = 16MB

      # 25% of memory
      shared_buffers = 8GB

      # Checkpoint every 1GB. (default)
      # increased after seeing many warninsg about frequent checkpoints
      min_wal_size = 128MB
      max_wal_size = 1GB

      # We can risk losing some transactions.
      synchronous_commit = off

      effective_cache_size = 16GB
    '';
    # FIXME: don't use 'trust'.
    authentication = ''
      host hydra all 10.254.1.3/32 trust
      local all root peer map=prometheus
    '';

    identMap = ''
      prometheus root root
      prometheus postgres-exporter root
    '';
  };

  networking = {
    firewall.interfaces.wg0.allowedTCPPorts = [ 5432 ];
    firewall.allowPing = true;
    firewall.logRefusedConnections = true;
  };

  services.prometheus.exporters.postgres = {
    enable = true;
    dataSourceName = "user=root database=hydra host=/run/postgresql sslmode=disable";
    firewallFilter = "-i wg0 -p tcp -m tcp --dport 9187";
    openFirewall = true;
  };

  fileSystems."/data" =
    { device = "/dev/disk/by-label/data";
      fsType = "ext4";
    };
}
