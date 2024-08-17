{ config, pkgs, ... }:

{
  systemd.services.pull-nixos-metrics = {
    description = "Pull nixos metrics from github:NixOS/nixos-metrics and push to local VictoriaMetrics";
    script =
      let
        inherit (config.services.victoriametrics) listenAddress;
        importURL = "http://localhost${listenAddress}/api/v1/import";
        resetURL = "http://localhost${listenAddress}/internal/resetRollupResultCache";
        dataURL = "https://raw.githubusercontent.com/NixOS/nixos-metrics/data/victoriametrics.jsonl";
        curl = "${pkgs.curl}/bin/curl";
      in
      ''
        ${curl} ${dataURL} | ${curl} -X POST --data-binary @- ${importURL}
        ${curl} -G ${resetURL}
      '';
    serviceConfig = {
      Type = "oneshot";
      User = "nobody";
    };
  };

  systemd.timers.pull-nixos-metrics = {
    description = "Pull nixos metrics, timed for after they're done updating each day.";
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "12:00:00";
  };

  services.backup.includesZfsDatasets = [ "/var/lib/victoriametrics" ];

  services.victoriametrics = {
    enable = true;
    retentionPeriod = 1200; # 100 years
  };
}
