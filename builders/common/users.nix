{
  config,
  lib,
  pkgs,
  ...
}:
let
  authorizedNixStoreKey =
    key:
    let
      environment = lib.concatStringsSep " " [
        "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ];
    in
    "command=\"${environment} ${config.nix.package}/bin/nix-store --serve --write\" ${key}";

  keys = import ../../keys.nix;
in

{
  users = {
    mutableUsers = false;
    users = {
      build = {
        isNormalUser = true;
        uid = 2000;
        openssh.authorizedKeys.keys = map authorizedNixStoreKey keys.ssh.users.hydra-queue-runner;
      };

      root.openssh.authorizedKeys.keys = keys.ssh.groups.infra-core;
    };
  };
}
