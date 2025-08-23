{ inputs, config, ... }:
let
  cfg = config;
in
{
  imports = [
    inputs.nixpkgs-swh.nixosModules.nixpkgs-swh
  ];
  config = {
    services = {
      nixpkgs-swh = {
        enable = true;
      };
      nginx = {
        enable = true;
        virtualHosts = {
          "nixpkgs-swh.nixos.org" = {
            enableACME = true;
            forceSSL = true;

            locations."/" = {
              root = cfg.services.nixpkgs-swh.outputDir;
              extraConfig = ''
                autoindex on;
              '';
            };
          };
        };
      };
    };
  };
}
