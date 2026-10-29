{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    # TODO: remove once we're on NixOS 26.11 which has the freescout module.
    "${inputs.nixpkgs-unstable}/nixos/modules/services/web-apps/freescout.nix"
    ../nginx.nix
  ];

  # TODO: remove once we're on NixOS 26.11.
  # What follows is a hack to make the freescout module from nixpkgs-unstable work on NixOS 26.05.
  # nixpkgs-unstable's freescout module uses structural phpOptions [0],
  # which was introduced in [1] which was not backported to 26.05.
  #
  # [0]: https://github.com/nixos/nixpkgs/commit/742ea2c8a744111a24d0bae075db0987fc26ce46
  # [1]: https://github.com/nixos/nixpkgs/commit/86c99622fd7bfb6e815e37880718350a10340ab9
  services.phpfpm.pools.freescout.phpOptions =
    assert config.system.nixos.release == "26.05";
    (lib.mkForce ''
      display_errors = On
      display_startup_errors = On
    '');

  services.freescout = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.freescout;
    domain = "freescout.nixos.org";

    settings.APP_KEY._secret = config.sops.secrets.freescout-app-key.path;

    databaseSetup = {
      enable = true;
      kind = "pgsql";
    };
  };

  services.nginx.virtualHosts.${config.services.freescout.domain} = {
    forceSSL = true;
    enableACME = true;
  };

  services.postgresqlBackup = {
    enable = true;
    databases = [ "freescout" ];
  };

  services.backup.includes = [
    "/var/lib/freescout"
    config.services.postgresqlBackup.location
  ];

  # How to generate:
  #
  #   $ cd non-critical-infra
  #   $ SECRET_PATH=secrets/freescout-app-key.umbriel
  #   $ echo "base64:$(nix run nixpkgs#openssl -- rand -base64 32)" > "$SECRET_PATH"
  #   $ sops encrypt --in-place "$SECRET_PATH"
  sops.secrets.freescout-app-key = {
    format = "binary";
    owner = config.services.postsrsd.user;
    group = config.services.postsrsd.group;
    sopsFile = ../../secrets/freescout-app-key.umbriel;
    restartUnits = [ "postsrsd.service" ];
  };
}
