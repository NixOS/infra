{ pkgs, ... }:

{
  services.prometheus = {
    scrapeConfigs = [
      {
        job_name = "rasdaemon";
        static_configs = [
          {
            targets = [
              # build
              "mimas.nixos.org:10029"
              "haumea.nixos.org:10029"
              "pluto.nixos.org:10029"

              # builders
              "elated-minsky.builder.nixos.org:10029"
              "sleepy-brown.builder.nixos.org:10029"
              "goofy-hopcroft.builder.nixos.org:10029"
              "hopeful-rivest.builder.nixos.org:10029"

              # non-critical
              "caliban.nixos.org:10029"
            ];
          }
        ];
      }
    ];

    ruleFiles = [
      (pkgs.writeText "rasdaemon.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "rasdaemon";
              rules = [
                {
                  alert = "MachineCheckError";
                  expr = ''
                    increase(rasdaemon_mce_records_total{mce_msg!="Corrected error, no action required."}[1h]) > 0
                  '';
                  labels.severity = "warning";
                  annotations.summary = "Machine check detected an error on {{ $labels.instance }}: {{ $labels.mce_msg }}";
                }
              ];
            }
          ];
        }
      ))
    ];
  };
}
