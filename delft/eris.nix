{ nodes, config, lib, pkgs, ... }:
let

in { deployment.targetEnv = "hetzner";
  deployment.hetzner.mainIPv4 = "138.201.32.77";

  networking.extraHosts = ''
    46.4.67.10 chef
    147.75.198.47 packet-epyc-1
    147.75.98.145 packet-t2-4
    147.75.65.54  packet-t2a-1
    147.75.79.198 packet-t2a-2
    147.75.198.170 packet-t2a-3
    147.75.111.30 packet-t2a-4
    '' + (let
        nums = lib.lists.range 1 9;
        name = num: ''
          37.153.215.191 mac${toString num}-host
          37.153.215.191 mac${toString num}-guest
        '';
      in lib.strings.concatMapStrings name nums);

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
      root = pkgs.writeTextDir "index.html" "check out /grafana and /prometheus";
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
      { job_name = "node";
        static_configs = [
	  {
	    targets = [
              "chef:9100"
            ];
	    labels.role = "hydra";
	  }
	  {
	    targets = [
              "packet-epyc-1:9100" "packet-t2-4:9100" "packet-t2a-1:9100"
              "packet-t2a-2:9100" "packet-t2a-3:9100" "packet-t2a-4:9100"
	      "chef:9100"
	    ];
	    labels.role = "builder";
	  }
	  {
	    targets = builtins.map (n: "mac${toString n}-host:6010") (lib.lists.range 1 9);
	    labels.mac = "host";
	    labels.role = "macos-hypervisor";
	  }
	  {
	    targets = builtins.map (n: "mac${toString n}-guest:6010") (lib.lists.range 1 9);
	    labels.mac = "guest";
	    labels.role = "builder";
	  }
	];
      }

      { job_name = "hydra";
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
