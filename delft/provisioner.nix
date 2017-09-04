{ config, lib, pkgs, ... }:

let

  hydra-provisioner = import ../../hydra-provisioner { inherit pkgs; inherit nixops; };
  nixops = pkgs.nixops;

in

{

  users.extraUsers.hydra-provisioner =
    { description = "Hydra provisioner";
      group = "hydra";
      home = "/var/lib/hydra-provisioner";
      useDefaultShell = true;
      createHome = true;
      openssh.authorizedKeys.keys = [ (import ../ssh-keys.nix).eelco ];
    };

  system.activationScripts.hydra-provisioner = lib.stringAfter [ "users" ]
    ''
      mkdir -m 0755 -p /var/lib/hydra/provisioner
      mkdir -m 0700 -p /var/lib/hydra-provisioner
      chown hydra-provisioner.hydra /var/lib/hydra-provisioner /var/lib/hydra/provisioner
    '';

  environment.systemPackages =
    [ hydra-provisioner
      nixops
      pkgs.awscli
    ];

  # FIXME: restrict PostgreSQL access.
  services.postgresql.identMap =
    ''
      hydra-users hydra-provisioner hydra
    '';

  services.hydra-dev.buildMachinesFiles =
    [ "/etc/nix/machines" "/var/lib/hydra/provisioner/machines" ];

  systemd.services.hydra-provisioner =
    { script =
        ''
          source /etc/profile
          while true; do
            timeout 3600 ${hydra-provisioner}/bin/hydra-provisioner /var/lib/hydra-provisioner/nixos-org-configurations/hydra-provisioner/conf.nix
            sleep 300
          done
        '';
      serviceConfig.User = "hydra-provisioner";
      serviceConfig.Restart = "always";
      serviceConfig.RestartSec = 60;
    };

  nix.nixPath = [ "${hydra-provisioner}/share/nix" ];
}
