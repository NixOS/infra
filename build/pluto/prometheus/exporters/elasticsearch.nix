{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

let
  port = 9114;
  listenAddress = "127.0.0.1";
  url = "https://nixos-search-7-1733963800.us-east-1.bonsaisearch.net";
  extraFlags = [
    "--es.all"
    "--es.indices"
    "--es.cluster_settings"
    "--es.snapshots"
  ];
in
{
  # Note that the credentials are technically in the nixos-search repo in plaintext,
  # so mostly using age here for good form.
  age.secrets.elasticsearch-exporter-env.file = ../../../secrets/elasticsearch-exporter-env.age;

  # Self-contained port of services.prometheus.exporters.elasticsearch
  # (nixpkgs PR #525622, not yet in our stable pin). Inlines the exporter
  # framework's default hardened unit; swap to the native option once it
  # reaches the pin.
  systemd.services.prometheus-elasticsearch-exporter = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Restart = "always";
      DynamicUser = true;
      User = "elasticsearch-exporter";
      Group = "elasticsearch-exporter";
      EnvironmentFile = config.age.secrets.elasticsearch-exporter-env.path;
      ExecStart = utils.escapeSystemdExecArgs (
        [
          (lib.getExe pkgs.prometheus-elasticsearch-exporter)
          "--web.listen-address=${listenAddress}:${toString port}"
          "--es.uri=${url}"
        ]
        ++ extraFlags
      );

      # framework hardening defaults
      PrivateTmp = true;
      WorkingDirectory = "/tmp";
      CapabilityBoundingSet = [ "" ];
      DeviceAllow = [ "" ];
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      UMask = "0077";
    };
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "prometheus-elasticsearch-exporter";
      static_configs = [ { targets = [ "127.0.0.1:${toString port}" ]; } ];
    }
  ];
}
