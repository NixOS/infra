{
  config,
  lib,
  pkgs,
  ...
}:

let
  environment = lib.concatStringsSep " " [
    "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
  ];

  authorizedNixStoreKey =
    key:
    "command=\"${environment} ${config.nix.package}/bin/nix-store --serve --store daemon --write\" ${key}";

  keys = import ../../keys.nix;
in

{
  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys =
    with keys.ssh;
    (map authorizedNixStoreKey users.hydra-queue-runner) ++ groups.infra-core;
}
