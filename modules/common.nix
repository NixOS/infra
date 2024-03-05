{ config, pkgs, lib, ... }:

with lib;

{
  imports = [
    ./backup.nix
  ];

  time.timeZone = "UTC";

  users.mutableUsers = false;

  users.extraUsers.root.openssh.authorizedKeys.keys =
    with import ../ssh-keys.nix; infra-core;

  nix = {
    settings = {
      cores = 0;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  environment.systemPackages =
    [ pkgs.emacs
      pkgs.git
      pkgs.gdb

      # jq is required by numtide/terraform-deploy-nixos-flakes.
      pkgs.jq
    ];

  services.openssh.enable = true;
}
