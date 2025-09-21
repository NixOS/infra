{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.prometheus.exporters.postgres = {
    enable = true;
    dataSourceName = "user=root database=hydra host=/run/postgresql sslmode=disable";
    openFirewall = true;
    firewallRules = ''
      ip6 saddr $prometheus_inet6 tcp dport ${toString config.services.prometheus.exporters.postgres.port} accept
      ip saddr $prometheus_inet4 tcp dport ${toString config.services.prometheus.exporters.postgres.port} accept
    '';
  };

  networking.firewall.interfaces."vlan4000".allowedTCPPorts = [ 5432 ];

  services.postgresql = {
    enable = true;
    enableJIT = true;
    package = pkgs.postgresql_16;
    dataDir = "/var/db/postgresql/16";
    # https://pgtune.leopard.in.ua/#/
    settings = {
      listen_addresses = lib.mkForce "10.0.40.1";

      # https://vadosware.io/post/everything-ive-seen-on-optimizing-postgres-on-zfs-on-linux/#zfs-related-tunables-on-the-postgres-side
      full_page_writes = "off";

      checkpoint_completion_target = "0.9";
      default_statistics_target = 100;

      log_duration = "off";
      log_statement = "none";

      # pgbadger-compatible logging
      log_transaction_sample_rate = 0.01;
      log_min_duration_statement = 5000;
      log_checkpoints = "on";
      log_connections = "on";
      log_disconnections = "on";
      log_lock_waits = "on";
      log_temp_files = 0;
      log_autovacuum_min_duration = 0;
      log_line_prefix = "user=%u,db=%d,app=%a,client=%h ";

      max_connections = 500;
      work_mem = "20MB";
      maintenance_work_mem = "2GB";

      # 25% of memory
      shared_buffers = "16GB";

      # Checkpoint every 1GB. (default)
      # increased after seeing many warninsg about frequent checkpoints
      min_wal_size = "1GB";
      max_wal_size = "2GB";
      wal_buffers = "16MB";

      max_worker_processes = 16;
      max_parallel_workers_per_gather = 8;
      max_parallel_workers = 16;

      # NVMe related performance tuning
      effective_io_concurrency = 200;
      random_page_cost = "1.1";

      # We can risk losing some transactions.
      synchronous_commit = "off";

      effective_cache_size = "16GB";

      # Enable JIT compilation if possible.
      jit = "on";

      # autovacuum and autoanalyze much more frequently:
      # at these values vacuum should run approximately
      # every 2 mass rebuilds, or a couple times a day
      # on the builds table. Some of those queries really
      # benefit from frequent vacuums, so this should
      # help. In particular, I'm thinking the jobsets
      # pages.
      autovacuum_vacuum_scale_factor = 0.02;
      autovacuum_analyze_scale_factor = 0.01;

      shared_preload_libraries = "pg_stat_statements";
      compute_query_id = "on";
    };

    # FIXME: don't use 'trust'.
    authentication = ''
      host hydra all 10.0.40.0/32 trust
      local all root peer map=prometheus
    '';

    identMap = ''
      prometheus root root
      prometheus postgres-exporter root
    '';
  };
}
