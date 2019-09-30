{ resources, config, lib, pkgs, ... }:
let
  inherit (lib) filterAttrs flip mapAttrsToList;

  macs = filterAttrs (_: v: (v.macosGuest or {}).enable or false) resources.machines;
in {
  imports =  [
    ../modules/prometheus
  ];
  deployment.targetEnv = "hetzner";
  deployment.hetzner.mainIPv4 = "138.201.32.77";


  networking.extraHosts = ''
    10.254.1.1 bastion
    10.254.1.2 chef
    10.254.1.3 ceres

    10.254.1.5 ike
    10.254.1.6 hydra
    10.254.1.7 lucifer
    10.254.1.8 wendy

    10.254.3.1 webserver

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
            labels.role = "unknown";
          }
          {
            targets = [
              "chef:9100"
            ];
            labels.role = "builder";
          }
          {
            targets = [
              "webserver:9100"
            ];
            labels.role = "webserver";
          }
          {
            targets = flip mapAttrsToList macs (machine: v: "${machine}:9101");
            labels.mac = "guest";
            labels.role = "builder";
          }
          {
            targets = flip mapAttrsToList macs (machine: v: "${machine}:9100");
            labels.mac = "host";
            labels.role = "builder";
          }
        ];
      }
      {
        job_name = "nixos";
        static_configs = [
          {
            targets = flip mapAttrsToList resources.machines (machine: v: "${v.networking.hostName}:9300");
          }
          {
            targets = [
              "webserver:9300"
            ];
            labels.role = "webserver";
          }
        ];
      }
      {
        job_name = "packet_nodes";
        file_sd_configs = [
          {
            files = [ "/var/lib/packet-sd/packet-sd.json" ];
            refresh_interval = "30s";
          }
        ];
        relabel_configs = [
          {
            source_labels = [ "__meta_packet_short_id" ];
            target_label = "__address__";
            replacement = "\${1}.packethost.net:9100";
            action = "replace";
          }
          {
            source_labels = [ "__meta_packet_facility" ];
            target_label = "facility";
          }
          {
            source_labels = [ "__meta_packet_short_id" ];
            target_label = "instance";
            replacement = "\${1}.packethost.net";
            action = "replace";
          }
          {
            source_labels = [ "__meta_packet_tags" ];
            target_label = "role";
            regex = ".*hydra.*";
            replacement = "builder";
            action = "replace";
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

      {
        job_name = "prometheus-packet-sd";
        metrics_path = "/metrics";
        static_configs = [
          {
            targets = [
              "127.0.0.1:9465"
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

  deployment.keys."packet-sd-env" = {
    keyFile = ../prometheus-packet-service-discovery;
    user = "packet-sd";
  };

  users.extraUsers.packet-sd = {
    description = "Prometheus Packet Service Discovery";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/packet-sd 0755 packet-sd - -"
    "f /var/lib/packet-sd/packet-sd.json 0644 packet-sd - -"
  ];

  systemd.services.prometheus-packet-sd = let
    sd = pkgs.callPackage ./prometheus/packet-sd.nix {};
  in {
    wantedBy = [ "multi-user.target" "prometheus.service" ];
    after = [ "network.target" ];

    serviceConfig = {
      User = "packet-sd";
      Group = "keys";
      ExecStart = "${sd}/bin/prometheus-packet-sd --output.file=/var/lib/packet-sd/packet-sd.json";
      EnvironmentFile = "/run/keys/packet-sd-env";
      Restart = "always";
      RestartSec = "60s";
    };
  };
}
