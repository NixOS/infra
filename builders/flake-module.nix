{ inputs, ... }:
{
  flake.nixosConfigurations =
    let
      mkNixOS =
        system: config:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            inputs.disko.nixosModules.disko

            ./common/hardening.nix
            ./common/network.nix
            ./common/nix.nix
            ./common/node-exporter.nix
            ./common/system.nix
            ./common/tools.nix
            ./common/update.nix
            ./common/users.nix
            ./common/ssh.nix

            ../modules/rasdaemon.nix

            config
          ];
        };
    in
    {
    };
}
