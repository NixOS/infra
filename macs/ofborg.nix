{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    ../non-critical-infra/modules/ofborg/ofborg-config.nix
  ];

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
    sopsFile = ./secrets/${config.networking.hostName}.yml;
  };
}
