{ config, pkgs, ... }:

let
  mkStaticProbe = module: targets: {
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
        replacement = "localhost:${toString config.services.prometheus.exporters.blackbox.port}";
      }
    ];
  };

  mkDnsSdProbe = module: dns_sd_config: {
    job_name = "blackbox-${module}";
    metrics_path = "/probe";
    params = {
      module = [ module ];
    };
    dns_sd_configs = [
      dns_sd_config
    ];
    relabel_configs = [
      {
        source_labels = [ "__address__" ];
        target_label = "__param_target";
      }
      {
        source_labels = [ "__address__" ];
        target_label = "host";
      }
      {
        source_labels = [ "__meta_dns_name" ];
        target_label = "instance";
      }
      {
        target_label = "__address__";
        replacement = "localhost:${toString config.services.prometheus.exporters.blackbox.port}";
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

          # From https://github.com/prometheus/blackbox_exporter/blob/53e78c2b3535ecedfd072327885eeba2e9e51ea2/example.yml#L120-L133
          modules.smtp_starttls = {
            prober = "tcp";
            timeout = "5s";
            tcp = {
              query_response = [
                { expect = "^220 ([^ ]+) ESMTP (.+)$"; }
                { send = "EHLO prober\r"; }
                { expect = "^250-STARTTLS"; }
                { send = "STARTTLS\r"; }
                { expect = "^220"; }
                { starttls = true; }
                { send = "EHLO prober\r"; }
                { expect = "^250-AUTH"; }
                { send = "QUIT\r"; }
              ];
            };
          };
        }
      );
    };

    scrapeConfigs = [
      (mkStaticProbe "https_success" [
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
      # TODO: remove this static probe once `umbriel` is our MX record, and
      # ImprovMX is out of the picture.
      # https://github.com/NixOS/infra/issues/485
      (mkStaticProbe "smtp_starttls_umbriel" [ "umbriel.nixos.org" ])
      (mkDnsSdProbe "smtp_starttls" {
        names = [
          "nixos.org"
        ];
        type = "MX";
        port = 25;
      })
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
                {
                  alert = "MxUnreachable";
                  expr = ''
                    probe_success{job="blackbox-smtp_starttls"} == 0
                  '';
                  for = "15m";
                  labels.severity = "warning";
                  annotations.summary = "Mail server {{ $labels.instance }} is unreachable";
                }
              ];
            }
          ];
        }
      ))
    ];
  };
}
