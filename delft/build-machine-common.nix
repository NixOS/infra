{ config, lib, pkgs, ... }:

with lib;

{
  nix.gc.automatic = true;
  nix.gc.dates = "*:45";
  nix.gc.options = ''--max-freed "$((128 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';

  # Randomize GC start times do we don't block all build machines at
  # the same time.
  systemd.timers.nix-gc.timerConfig.RandomizedDelaySec = mkForce "1800";

  users.extraUsers.root.openssh.authorizedKeys.keys = singleton
    ''
      command="nix-store --serve --write" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOdxl6gDS7h3oeBBja2RSBxeS51Kp44av8OAJPPJwuU/ hydra-queue-runner@rhea
    '';
}
