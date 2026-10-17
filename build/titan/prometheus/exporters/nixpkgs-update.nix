{ pkgs, ... }:
{
  services.prometheus.ruleFiles = [
    (pkgs.writeText "nixpkgs-update.rules" (
      builtins.toJSON {
        groups = [
          {
            name = "nixpkgs-update";
            rules = [
              {
                alert = "NixpkgsUpdateStalled";
                expr = ''
                  time() - nixpkgs_update_last_job_finished_timestamp_seconds > 30 * 60
                '';
                for = "10m";
                labels.severity = "warning";
                annotations.summary = "No nixpkgs-update job finished on {{ $labels.instance }} for 30 minutes.";
              }
              {
                alert = "NixpkgsUpdateNoSuccessfulJobs";
                expr = ''
                  sum by (instance) (nixpkgs_update_jobs_finished_1h{exit_code="0"}) == 0
                '';
                for = "3h";
                labels.severity = "warning";
                annotations.summary = "No nixpkgs-update job exited successfully on {{ $labels.instance }} for 3 hours.";
              }
              {
                alert = "NixpkgsUpdateFetcherStale";
                expr = ''
                  time() - nixpkgs_update_fetcher_last_complete_run_timestamp_seconds > 24 * 3600
                '';
                for = "30m";
                labels.severity = "warning";
                annotations.summary = "Fetcher {{ $labels.fetcher }} on {{ $labels.instance }} has not completed a run for a day.";
              }
              {
                alert = "NixpkgsUpdateMetricsStale";
                expr = ''
                  time() - node_textfile_mtime_seconds{file=~".*nixpkgs-update.prom"} > 30 * 60
                '';
                for = "10m";
                labels.severity = "warning";
                annotations.summary = "nixpkgs-update metrics on {{ $labels.instance }} are no longer refreshed.";
              }
            ];
          }
        ];
      }
    ))
  ];
}
