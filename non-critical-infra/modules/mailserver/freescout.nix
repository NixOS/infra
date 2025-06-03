{
  inputs,
  config,
  pkgs,
  ...
}:

{
  imports = [
    inputs.freescout.nixosModules.freescout
    ../nginx.nix
  ];

  services.freescout = {
    enable = true;
    # Workaround for https://cyberchaos.dev/e1mo/freescout-nix-flake/-/merge_requests/1
    package = inputs.freescout.packages.${pkgs.system}.default;
    domain = "freescout.nixos.org";

    settings.APP_KEY._secret = config.sops.secrets.freescout-app-key.path;

    databaseSetup.enable = true;

    nginx = {
      forceSSL = true;
      enableACME = true;
    };
  };

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
