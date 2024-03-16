{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11-small";

  inputs.agenix.url = "github:ryantm/agenix";
  inputs.agenix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.colmena.url = "github:zhaofengli/colmena";
  inputs.colmena.inputs.nixpkgs.follows = "nixpkgs";

  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  inputs.hydra.url = "github:NixOS/hydra/hydra.nixos.org";
  inputs.nix.follows = "hydra/nix";

  inputs.hydra-scale-equinix-metal.url = "github:DeterminateSystems/hydra-scale-equinix-metal";

  inputs.nix-netboot-serve.url = "github:DeterminateSystems/nix-netboot-serve";

  inputs.nixos-channel-scripts.url = "github:NixOS/nixos-channel-scripts";
  inputs.nixos-channel-scripts.inputs.nixpkgs.follows = "nixpkgs";

  inputs.rfc39.url = "github:NixOS/rfc39";
  inputs.rfc39.inputs.nixpkgs.follows = "nixpkgs";

  outputs = flakes @ { self, agenix, colmena, disko, hydra, hydra-scale-equinix-metal, nix, nixpkgs, nixos-channel-scripts, nix-netboot-serve, rfc39 }:
    let
      inherit (nixpkgs) lib;

      flakesModule = {
        imports = [
          agenix.nixosModules.age
          disko.nixosModules.disko
          hydra.nixosModules.hydra
          hydra-scale-equinix-metal.nixosModules.default
          nix-netboot-serve.nixosModules.nix-netboot-serve
        ];

        nixpkgs.overlays = [
          nix.overlays.default
          nixos-channel-scripts.overlays.default
          rfc39.overlays.default
        ];
      };
    in {
      nixosConfigurations.haumea = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          flakesModule
          ./haumea
        ];
      };

      nixosConfigurations.pluto = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          flakesModule
          ./pluto
        ];
      };

      nixosConfigurations.rhea = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          flakesModule
          ./rhea/configuration.nix
        ];
      };

      colmena = {
        meta = {
          description = "NixOS.org infrastructure";
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
          };
        };
      } // builtins.mapAttrs
        (name: value: {
          nixpkgs.system = value.config.nixpkgs.system;
          imports = value._module.args.modules;
          deployment = {
            targetHost = "${name}.nixos.org";
          };
        }) (self.nixosConfigurations);

      # TODO: flake-utils.lib.eachDefaultSystem
      devShell.x86_64-linux = let
        pkgs = import nixpkgs { system = "x86_64-linux"; };
      in pkgs.mkShell {
        buildInputs = with pkgs; [
          agenix.packages.x86_64-linux.agenix
          colmena.packages.x86_64-linux.colmena
        ];
      };
    };
}
