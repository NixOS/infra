{ lib, pkgs, ... }:

let
  channels = pkgs.writeText "channels.json" (
    builtins.toJSON (import ../../../../channels.nix).channels
  );
in
{
  systemd.services.channel-update-exporter = {
    description = "Check all active channels' last-update times";
    path = [
      (pkgs.python3.withPackages (
        pypkgs: with pypkgs; [
          requests
          prometheus-client
          python-dateutil
        ]
      ))
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      DynamicUser = true;
      ExecStart = "${./channel-exporter.py} ${channels}";
    };
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "channel-updates";
      metrics_path = "/";
      static_configs = [ { targets = [ "127.0.0.1:9402" ]; } ];
    }
  ]
  ++ lib.mapAttrsToList (name: value: {
    job_name = "channel-job-${name}";
    scheme = "https";
    scrape_interval = "5m";
    metrics_path = "/job/${value.job}/prometheus";
    static_configs = [
      {
        labels = {
          current = if value.status != "unmaintained" then "1" else "0";
          channel = name;
        };
        targets = [ "hydra.nixos.org:443" ];
      }
    ];
  }) (import ../../../../channels.nix).channels;
}
