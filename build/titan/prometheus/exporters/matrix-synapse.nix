{
  lib,
  ...
}:

{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "matrix_synapse";
      scheme = "https";

      static_configs = lib.flatten (
        map
          (
            {
              job,
              indices,
            }:
            map (index: {
              targets = [ "matrix.nixos.org:443" ];
              labels = {
                job = "synapse${if job != "main" then "-${job}" else ""}";
                __metrics_path__ = "/metrics/${job}${toString index}";
              }
              // lib.optionalAttrs (index != null) {
                index = toString index;
              };
            }) indices
          )
          [
            {
              job = "main";
              indices = [ null ];
            }
            {
              job = "client";
              indices = [
                1
                2
                3
                4
              ];
            }
            {
              job = "federation_sender";
              indices = [
                1
                2
                3
                4
              ];
            }
          ]
      );
    }
  ];
}
