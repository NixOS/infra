{ inputs, config, ... }:
{
  imports = [
    inputs.nixpkgs-swh.nixosModules.nixpkgs-swh
  ];
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
            root = config.services.nixpkgs-swh.outputDir;
            extraConfig = ''
              autoindex on;
            '';
          };
        };
      };
    };
  };
}
