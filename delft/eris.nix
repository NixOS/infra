{ resources, config, lib, pkgs, ... }:
let
  inherit (lib) filterAttrs flip mapAttrsToList;

  macs = filterAttrs (_: v: (v.macosGuest or {}).enable or false) resources.machines;
in {
  deployment.targetEnv = "hetzner";
  deployment.hetzner.mainIPv4 = "138.201.32.77";


  networking.extraHosts = ''
    147.75.79.198 packet-t2a-2
    147.75.198.170 packet-t2a-3
    147.75.74.238 packet-t2a5-qc-centriq-1
    147.75.107.178 packet-t2a6-ampere-1

    10.254.1.1 bastion
    10.254.1.2 chef
    10.254.1.3 ceres

    10.254.1.5 ike
    10.254.1.6 hydra
    10.254.1.7 lucifer
    10.254.1.8 wendy
    10.254.1.9 packet-epyc-1
    10.254.1.10 packet-t2-4

    '' + (toString (flip mapAttrsToList macs (machine: v: ''
    ${v.deployment.targetHost} ${machine}
    '')));

  networking.firewall.allowedTCPPorts = [
    443 80 # nginx
    9090 # prometheus's web UI
    9200 # hydra-queue-runner rexporter
  ];

  services.nginx = {
    enable = true;
    virtualHosts."status.nixos.org" = {
      enableACME = true;
      forceSSL = true;
      root = pkgs.writeTextDir "index.html" ''
        <ul>
          <li><a href="/grafana">Grafana</a></li>
          <li><a href="/prometheus">Prometheus</a></li>
        </ul>
      '';
      locations."/grafana/".proxyPass = "http://${config.services.grafana.addr}:${toString config.services.grafana.port}/";
      locations."/prometheus".proxyPass = "http://${config.services.prometheus.listenAddress}";
    };
  };

  services.prometheus = {
    enable = true;
    extraFlags = [
      "-storage.local.retention=${toString (120 * 24)}h"
      "--web.external-url=https://status.nixos.org/prometheus/"
    ];

    globalConfig.scrape_interval = "15s";
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
           targets = flip mapAttrsToList resources.machines (machine: v: "${v.networking.hostName}:9100");
          }
          {
            targets = [
              "packet-epyc-1:9100" "packet-t2-4:9100"
              "packet-t2a-2:9100" "packet-t2a-3:9100"
              "packet-t2a5-qc-centriq-1:9100" "packet-t2a6-ampere-1:9100"
              "chef:9100"
            ];
            labels.role = "builder";
          }
          {
            targets = flip mapAttrsToList macs (machine: v: "${machine}:9101");
            labels.mac = "guest";
            labels.role = "builder";
          }
        ];
      }

      {
        job_name = "hydra";
        metrics_path = "/";
        static_configs = [
          {
            targets = [
              "status.nixos.org:9200"
            ];
          }
        ];
      }
    ];
  };

  services.grafana = {
    enable = true;
    auth.anonymous.enable = true;
    users.allowSignUp = true;
    addr = "0.0.0.0";
    domain = "status.nixos.org";
    rootUrl = "https://status.nixos.org/grafana/";
  };

  systemd.services.prometheus-hydra-exporter = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "60s";
      PrivateTmp =  true;
      WorkingDirectory = "/tmp";
      ExecStart = let
          python = pkgs.python3.withPackages (p: [
             p.requests p.prometheus_client
          ]);
        in ''
          ${python}/bin/python ${./prometheus/hydra-queue-runner-reexporter.py}
      '';
    };
  };
}
