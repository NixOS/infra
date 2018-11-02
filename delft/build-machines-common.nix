{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ./common.nix ];

  nix.gc.automatic = true;
  nix.gc.dates = "*:45";
  nix.gc.options = ''--max-freed "$((128 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';

  # Randomize GC start times do we don't block all build machines at
  # the same time.
  systemd.timers.nix-gc.timerConfig.RandomizedDelaySec = "1800";

  users.extraUsers.root.openssh.authorizedKeys.keys = singleton
    ''
      command="nix-store --serve --write" ${readFile ./id_buildfarm.pub}
    '';
}
