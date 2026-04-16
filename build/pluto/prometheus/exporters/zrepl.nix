{ pkgs, ... }:

{
  services.prometheus = {
    scrapeConfigs = [
      {
        job_name = "zrepl";
        static_configs = [
          {
            labels.role = "database";
            targets = [
              "titan.nixos.org:9811"
            ];
          }
        ];
      }
    ];

    ruleFiles = [
      (pkgs.writeText "zrepl.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "zrepl";
              rules = [
                {
                  alert = "ZreplLongTimeNoSuccess";
                  expr = ''
                    time() - zrepl_replication_last_successful > ${toString (6 * 60 * 60)}
                  '';
                  for = "6h";
                  labels.severity = "warning";
                  annotations.summary = "zrepl job {{ $labels.zrepl_job }} has not succeeded recently.";
                }
              ];
            }
          ];
        }
      ))
    ];
  };
}
