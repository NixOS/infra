{
  config,
  lib,
  pkgs,
  ...
}:
let
  sshKeys = {
    hydra-queue-runner-rhea = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOdxl6gDS7h3oeBBja2RSBxeS51Kp44av8OAJPPJwuU/ hydra-queue-runner@rhea";
  };

  authorizedNixStoreKey =
    key:
    let
      environment = lib.concatStringsSep " " [
        "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ];
    in
    "command=\"${environment} ${config.nix.package}/bin/nix-store --serve --write\" ${key}";
in

{
  users = {
    mutableUsers = false;
    users = {
      build = {
        isNormalUser = true;
        uid = 2000;
        openssh.authorizedKeys.keys = [
          (authorizedNixStoreKey sshKeys.hydra-queue-runner-rhea)
        ];
      };

      root.openssh.authorizedKeys.keys = (import ../../ssh-keys.nix).infra-core;
    };
  };
}
