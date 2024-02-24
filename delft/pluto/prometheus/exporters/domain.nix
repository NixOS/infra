{ pkgs
, ...
}:

{
  services.prometheus = {
    exporters.domain = {
      enable = true;
      listenAddress = "localhost";
    };

    scrapeConfigs = [ {
      # https://github.com/caarlos0/domain_exporter#configuration
      job_name = "domain";
      metrics_path = "/probe";
      relabel_configs = [ {
        source_labels = [ "__address__" ];
        target_label = "__param_target";
      } {
        target_label = "__address__";
        replacement = "localhost:9222";
      } ];
      static_configs = [ {
        targets = [
          "nix.ci"
          "nix.dev"
          "nixos.org"
          "ofborg.org"
        ];
      } ];
    } ];

    ruleFiles = [
      (pkgs.writeText "domain-exporter.rules" (builtins.toJSON {
        groups = [ {    
          name = "domain";
          rules = [ {
            alert = "DomainExpiry";
            expr = "domain_expiry_days < 30";
            for = "1h";
            labels.severity = "warning";
            annotations.summary = "Domain {{ $labels.domain }} will expire in less than 30 days";
          } ];
        } ];
      }))
    ];
  };
}
