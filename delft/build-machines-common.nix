{ config, pkgs, ... }:

with pkgs.lib;
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

  users.extraUsers.root.openssh.authorizedKeys.keys = singleton
    ''
      command="nix-store --serve --write" ${readFile ./id_buildfarm.pub}
    '';
}
