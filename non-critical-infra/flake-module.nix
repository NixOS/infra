{
  inputs,
  lib,
  ...
}:
{
  colmena.hosts = {
    caliban = { };
    umbriel = { };
    staging-hydra = { };

    # ofborg
    "core01.ofborg.org".targetHost = "138.199.148.47";
    "eval01.ofborg.org".targetHost = "95.217.15.9";
    "eval02.ofborg.org".targetHost = "95.216.209.162";
    "eval03.ofborg.org".targetHost = "37.27.189.4";
    "eval04.ofborg.org".targetHost = "95.217.18.12";
    "build01.ofborg.org".targetHost = "185.119.168.10";
    "build02.ofborg.org".targetHost = "185.119.168.11";
    "build03.ofborg.org".targetHost = "185.119.168.12";
    "build04.ofborg.org".targetHost = "185.119.168.13";
    "build05.ofborg.org".targetHost = "142.132.171.106";
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
