{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    ../../non-critical-infra/modules/ofborg/ofborg-config.nix
  ];

  # Manage user for ofborg, this enables creating/deleting users
  # depending on what modules are enabled.
  users = {
    users.ofborg.home = "/private/var/lib/ofborg";
    users.root = {
      # bash doesn't export /run/current-system/sw/bin to $PATH,
      # which we need for nix-store
      shell = "/bin/zsh";
      openssh.authorizedKeys.keys = (import ../../keys.nix).ssh.groups.ofborg;
    };
  };

  services.ofborg = {
    enable = true;
    package = pkgs.ofborg;
    configFile = "/etc/ofborg.json";
  };

  nixpkgs.overlays = [
    (_self: super: {
      ofborg = inputs.ofborg.packages.${super.stdenv.hostPlatform.system}.pkg;
    })
  ];

  sops.secrets."ofborg/builder-rabbitmq-password" = {
    owner = "ofborg";
    sopsFile = ../secrets/${config.networking.localHostName}.yml;
  };
}
