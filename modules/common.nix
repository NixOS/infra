{ config, pkgs, lib, ... }:

with lib;

{
  time.timeZone = "Europe/Amsterdam";

  users.mutableUsers = false;

  users.extraUsers.root.openssh.authorizedKeys.keys =
     with import ../ssh-keys.nix; [ eelco rob ];

  nix.useSandbox = true;
  nix.buildCores = 0;
  nix.nixPath = [ "nixpkgs=channel:nixos-19.09-small" ];
  nix.extraOptions =
    ''
      experimental-features = nix-command flakes ca-references
    '';

  environment.systemPackages =
    [ pkgs.emacs
      pkgs.git
      pkgs.gdb
    ];
}
