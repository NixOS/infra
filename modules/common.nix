{ config, pkgs, lib, ... }:

with lib;

{
  time.timeZone = "Europe/Amsterdam";

  users.mutableUsers = false;

  users.extraUsers.root.openssh.authorizedKeys.keys =
    (import ../ssh-keys.nix).infra-core;

  nix.useSandbox = true;
  nix.buildCores = 0;
  nix.extraOptions =
    ''
      experimental-features = nix-command flakes
    '';

  environment.systemPackages =
    [ pkgs.emacs
      pkgs.git
      pkgs.gdb
    ];

  services.sshd.enable = true;
}
