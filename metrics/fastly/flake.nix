{
  outputs = { self, nixpkgs }: {
    nixosModules.nix-metrics = { config, pkgs, ... }: {

      users.users.nix-metrics =
        { isNormalUser = true;
          description = "Nix Metrics Collection";
        };

      systemd.services.process-raw-nix-logs = {
        description = "Process Raw nixos.org Logs";
        serviceConfig.Type = "oneshot";
        serviceConfig.User = "nix-metrics";
        path =
          [ pkgs.awscli
            pkgs.jq
          ];
        script =
          ''
            cd ${./.}
            ./cron.sh
          '';
        startAt = "Tue 07:30";
       };

    };
  };
}
