{
  inputs,
  lib,
  ...
}:
{
  colmena.hosts = {
    caliban = { };
    umbriel = { };
  };
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
            inputs.sops-nix.nixosModules.sops
          ];
          extraModules = [ inputs.colmena.nixosModules.deploymentOptions ];

        }
      ) (importConfig ./hosts);

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
