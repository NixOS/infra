{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.prometheus.exporters.postgres = {
    enable = true;
    # CREATE USER "postgres-exporter";
    # GRANT pg_monitor TO "postgres-exporter";
    dataSourceName = "user=postgres-exporter database=hydra host=/run/postgresql sslmode=disable";
    openFirewall = true;
    firewallRules = ''
      ip6 saddr $prometheus_inet6 tcp dport ${toString config.services.prometheus.exporters.postgres.port} accept
      ip saddr $prometheus_inet4 tcp dport ${toString config.services.prometheus.exporters.postgres.port} accept
    '';
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    # https://pgtune.leopard.in.ua/#/
    # https://vadosware.io/post/everything-ive-seen-on-optimizing-postgres-on-zfs-on-linux/#zfs-related-tunables-on-the-postgres-side
    settings = {
      # no page tearing on ZFS
      full_page_writes = "off";

      # avoid zero-filling with ZFS
      wal_init_zero = "off";
      wal_recycle = "off";

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

      max_worker_processes = 48;
      max_parallel_workers_per_gather = 4;
      max_parallel_workers = 48;
      max_parallel_maintenance_workers = 4;

      max_connections = 100;
      work_mem = "150MB";
      maintenance_work_mem = "8GB";

      # 25% of memory
      shared_buffers = "32GB";

      # Reduce WAL file creation churn
      min_wal_size = "1GB";
      max_wal_size = "4GB";

      # Shared memory allocation before writing WAL to disk
      wal_buffers = "16MB";

      # Async I/O over shared ringbuffer with the kernel
      io_method = "io_uring";

      # NVMe related performance tuning
      effective_io_concurrency = 1000;
      random_page_cost = "1.1";

      # query planner estimate for memory available for disk caching
      effective_cache_size = "96GB";

      # With ZFS we can risk losing some transactions.
      synchronous_commit = "off";

      # Try to allocate huge pages, if possible
      huge_pages = "try";

      # Only useful for long-running CPU-bound queries
      jit = "off";

      # autovacuum and autoanalyze much more frequently:
      # at these values vacuum should run approximately
      # every 2 mass rebuilds, or a couple times a day
      # on the builds table. Some of those queries really
      # benefit from frequent vacuums, so this should
      # help. In particular, I'm thinking the jobsets
      # pages.
      autovacuum_vacuum_scale_factor = 0.02; # down from 0.2
      autovacuum_analyze_scale_factor = 0.01; # down from 0.1

      shared_preload_libraries = "pg_stat_statements";
      compute_query_id = "on";
    };

    authentication = lib.mkBefore ''
      local all postgres-exporter peer
      local hydra zrepl peer map=zrepl
    '';

    identMap = ''
      zrepl root zrepl
    '';
  };
}
