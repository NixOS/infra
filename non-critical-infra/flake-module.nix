{
  self,
  inputs,
  lib,
  ...
}:
{
  flake =
    let
      importConfig =
        path:
        (lib.mapAttrs (name: _value: import (path + "/${name}/default.nix")) (
          lib.filterAttrs (_: v: v == "directory") (builtins.readDir path)
        ));
    in
    {
      nixosConfigurations = builtins.mapAttrs (
        _name: value:
        inputs.nixpkgs.lib.nixosSystem {
          inherit lib;
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
          };
          modules = [
            value
            inputs.disko.nixosModules.disko
            inputs.first-time-contribution-tagger.nixosModule
            inputs.simple-nixos-mailserver.nixosModule
            inputs.sops-nix.nixosModules.sops
          ];
          extraModules = [ inputs.colmena.nixosModules.deploymentOptions ];

        }
      ) (importConfig ./hosts);

      colmena =
        {
          meta = {
            nixpkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
            nodeNixpkgs = builtins.mapAttrs (_: v: v.pkgs) self.nixosConfigurations;
            nodeSpecialArgs = builtins.mapAttrs (_: v: v._module.specialArgs) self.nixosConfigurations;
            specialArgs.lib = lib;
          };
        }
        // builtins.mapAttrs (_: v: {
          deployment.tags = [ "non-critical-infra" ];
          imports = v._module.args.modules;
        }) self.nixosConfigurations;
    };

  perSystem =
    { inputs', pkgs, ... }:
    {
      packages.encrypt-email = pkgs.callPackage ./packages/encrypt-email { };

      devShells.non-critical-infra = pkgs.mkShellNoCC {
        packages = [
          inputs'.colmena.packages.colmena
          pkgs.sops
          pkgs.ssh-to-age
        ];
      };
    };
}
