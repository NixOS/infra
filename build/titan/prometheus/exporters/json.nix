{ config, pkgs, ... }:

{
  services.prometheus = {
    exporters.json = {
      enable = true;
      listenAddress = "localhost";

      configFile = (pkgs.formats.yaml { }).generate "json-exporter-config.yml" {
        modules.matrix-federation-checker = {
          metrics = [
            {
              name = "matrix_homeserver_federation_ok";
              path = "{.FederationOK}";
              help = "False if there's any problem with federation reported.";
              type = "value";
              value_type = "gauge";
            }
          ];
        };
      };
    };

    scrapeConfigs = [
      {
        job_name = "matrix-federation-checker";
        metrics_path = "/probe";
        params = {
          module = [ "matrix-federation-checker" ];
        };
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__address__" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "localhost:${toString config.services.prometheus.exporters.json.port}";
          }
        ];

        static_configs = [
          {
            targets = [ "https://federationtester.matrix.org/api/report?server_name=nixos.org" ];
            labels.matrix_instance = "nixos.org";
          }
        ];
      }
    ];

    ruleFiles = [
      (pkgs.writeText "matrix-federation.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "matrix-federation";
              rules = [
                {
                  alert = "MatrixFederationFailure";
                  expr = "matrix_homeserver_federation_ok < 1";
                  for = "30m";
                  labels.severity = "warning";
                  annotations.summary = "Matrix federation for {{ $labels.matrix_instance }} appears to be failing.";
                }
              ];
            }
          ];
        }
      ))
    ];
  };
}
