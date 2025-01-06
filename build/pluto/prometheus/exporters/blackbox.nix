{ pkgs, ... }:

let
  mkProbe = module: targets: {
    job_name = "blackbox-${module}";
    metrics_path = "/probe";
    params = {
      module = [ module ];
    };
    static_configs = [ { inherit targets; } ];
    relabel_configs = [
      {
        source_labels = [ "__address__" ];
        target_label = "__param_target";
      }
      {
        source_labels = [ "__param_target" ];
        target_label = "instance";
      }
      {
        target_label = "__address__";
        replacement = "localhost:9115";
      }
    ];
  };
in

{
  services.prometheus = {
    exporters.blackbox = {
      enable = true;
      listenAddress = "127.0.0.1";
      configFile = pkgs.writeText "probes.yml" (
        builtins.toJSON {
          modules.https_success = {
            prober = "http";
            tcp.tls = true;
            http.headers.User-Agent = "blackbox-exporter";
          };
        }
      );
    };

    scrapeConfigs = [
      (mkProbe "https_success" [
        "https://cache.nixos.org"
        "https://channels.nixos.org"
        "https://common-styles.nixos.org"
        "https://discourse.nixos.org"
        "https://hydra.nixos.org"
        "https://mobile.nixos.org"
        "https://monitoring.nixos.org"
        "https://nixos.org"
        "https://planet.nixos.org"
        "https://releases.nixos.org"
        "https://status.nixos.org"
        "https://survey.nixos.org"
        "https://tarballs.nixos.org"
        "https://weekly.nixos.org"
        "https://wiki.nixos.org"
        "https://www.nixos.org"
        "https://tracker.security.nixos.org"
      ])
    ];

    ruleFiles = [
      (pkgs.writeText "blackbox-exporter.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "blackbox";
              rules = [
                {
                  alert = "CertificateExpiry";
                  expr = ''
                    probe_ssl_earliest_cert_expiry - time() < 86400 * 14
                  '';
                  for = "15m";
                  labels.severity = "warning";
                  annotations.summary = "Certificate for {{ $labels.instance }} is expiring soon.";
                }
                {
                  alert = "HttpUnreachable";
                  expr = ''
                    probe_success{job="blackbox-https_success"} == 0
                  '';
                  for = "15m";
                  labels.severity = "warning";
                  annotations.summary = "Endpoint {{ $labels.instance }} is unreachable";
                }
              ];
            }
          ];
        }
      ))
    ];
  };
}
