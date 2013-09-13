{ config, pkgs, ... }:

with pkgs.lib;
let
  m3chown = pkgs.writeScript "chown-tmp-m3" ''
    #! /bin/sh
    set -e
    if [[ -d /tmp/m3 ]]; then
      chmod ug+w -R /tmp/m3
    fi
  '';
in
{
  require = [ ./common.nix ];

  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.copyKernels = true;

  fileSystems =
    [ { mountPoint = "/";
        label = "nixos";
        options = "noatime";
      }
    ];

  nix.gc.automatic = true;
  nix.gc.dates = "03,09,15,21:15";
  nix.gc.options = ''--max-freed "$((100 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';

  services.cron.systemCronJobs = [
    "0,30 * * * * ${m3chown}"
  ];

  users.extraUsers =
    [ { name = "buildfarm";
        description = "Hydra unprivileged build slave";
        group = "users";
        home = "/home/buildfarm";
        useDefaultShell = true;
        createHome = true;
        isSystemUser = false;
      }
    ];

  # !!! Should have a NixOS option for installing files into a declarative user account.
  system.activationScripts.buildfarmSSHKey = stringAfter [ "users" ]
    ''
      mkdir -m 700 -p /home/buildfarm/.ssh
      cp ${./id_buildfarm.pub} /home/buildfarm/.ssh/authorized_keys
      chown -R buildfarm.users /home/buildfarm/.ssh
    '';
}
