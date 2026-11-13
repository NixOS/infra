{ pkgs, ... }:

{
  services.prometheus.ruleFiles = [
    (pkgs.writeText "up.rules" (
      builtins.toJSON {
        groups = [
          {
            name = "up";
            rules = [
              {
                alert = "NotUp";
                expr = ''
                  up == 0
                '';
                for = "10m";
                labels.severity = "warning";
                annotations.summary = "scrape job {{ $labels.job }} is failing on {{ $labels.instance }}";
              }
            ];
          }
        ];
      }
    ))
  ];
}
