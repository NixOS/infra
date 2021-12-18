{ config, pkgs, ... }:
let
  exporter = pkgs.fetchFromGitHub {
    owner = "grahamc";
    repo = "prometheus-github-exporter";
    rev = "01b6f8ef06b694411baf10f49e7b05afb26ab307";
    sha256 = "sha256-Sk/ynhPeXQVIgyZJ3Gj1VynJhPWmBHjrRnGYLjnJvio=";
  };

  config = pkgs.writeText "config.json" (builtins.toJSON {
    port = 9401;
    repos = [
      "NixOS/nixpkgs"
      "NixOS/nix"
    ];
  });
in {
  users.users.github-exporter = {
    description = "Prometheus Github Exporter";
    isSystemUser = true;
    group = "github-exporter";
  };
  users.groups.github-exporter = {};

  systemd.services.prometheus-github-exporter = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      User = "github-exporter";
      Restart = "always";
      RestartSec = "60s";
      PrivateTmp =  true;
    };

    path = [
      (pkgs.python3.withPackages (p: [ p.prometheus_client p.requests ]))
    ];

    script = "exec python3 ${exporter}/scrape.py ${config}";
  };
}
