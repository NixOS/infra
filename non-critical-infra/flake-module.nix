{
  inputs,
  lib,
  ...
}:
{
  colmena.hosts = {
    caliban = { };
    umbriel = { };
    staging-hydra.targetHost = "staging-hydra.nixos.org";

    # ofborg
    "core01.ofborg.org".targetHost = "core01.ofborg.org";
    "eval01.ofborg.org".targetHost = "eval01.ofborg.org";
    "eval02.ofborg.org".targetHost = "eval02.ofborg.org";
    "eval03.ofborg.org".targetHost = "eval03.ofborg.org";
    "eval04.ofborg.org".targetHost = "eval04.ofborg.org";
    "build01.ofborg.org".targetHost = "build01.ofborg.org";
    "build02.ofborg.org".targetHost = "build02.ofborg.org";
    "build03.ofborg.org".targetHost = "build03.ofborg.org";
    "build04.ofborg.org".targetHost = "build04.ofborg.org";
    "build05.ofborg.org".targetHost = "build05.ofborg.org";
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
