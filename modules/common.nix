{ config, pkgs, lib, ... }:

with lib;

{
  time.timeZone = "Europe/Amsterdam";

  users.mutableUsers = false;

  users.extraUsers.root.openssh.authorizedKeys.keys =
     with import ../ssh-keys.nix; [ eelco rob ];

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
