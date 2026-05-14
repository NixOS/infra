{
  config,
  lib,
  pkgs,
  ...
}:

let
  sshKeys = {
    hydra-queue-runner = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOdxl6gDS7h3oeBBja2RSBxeS51Kp44av8OAJPPJwuU/ hydra-queue-runner@rhea";
  };

  environment = lib.concatStringsSep " " [
    "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
  ];

  authorizedNixStoreKey =
    key:
    "command=\"${environment} ${config.nix.package}/bin/nix-store --serve --store daemon --write\" ${key}";
in

{
  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    (authorizedNixStoreKey sshKeys.hydra-queue-runner)
  ]
  ++ (import ../keys.nix).ssh.groups.infra-core;
}
