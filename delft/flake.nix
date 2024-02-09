{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11-small";

  inputs.agenix.url = "github:ryantm/agenix";
  inputs.agenix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.hydra.url = "github:NixOS/hydra/nix-2.19";
  inputs.nix.follows = "hydra/nix";

  inputs.hydra-scale-equinix-metal.url = "github:DeterminateSystems/hydra-scale-equinix-metal";

  inputs.nix-netboot-serve.url = "github:DeterminateSystems/nix-netboot-serve";

  inputs.rfc39.url = "github:NixOS/rfc39";
  inputs.rfc39.inputs.nixpkgs.follows = "nixpkgs";

  outputs = flakes @ { self, agenix, hydra, hydra-scale-equinix-metal, nix, nixpkgs, nix-netboot-serve, rfc39 }:
    let
      inherit (nixpkgs) lib;

      flakesModule = {
        imports = [
          agenix.nixosModules.age
          hydra.nixosModules.hydra
          hydra-scale-equinix-metal.nixosModules.default
          nix-netboot-serve.nixosModules.nix-netboot-serve
        ];

        nixpkgs.overlays = [
          nix.overlays.default
          rfc39.overlays.default
        ];
      };
    in {
      nixosConfigurations.eris = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          flakesModule
          ./eris.nix
          ./eris-physical.nix
        ];
      };

      nixosConfigurations.haumea = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          flakesModule
          ./haumea.nix
          ./haumea-physical.nix
        ];
      };

      nixosConfigurations.rhea = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          flakesModule
          ./rhea/configuration.nix
        ];
      };

      nixopsConfigurations.default =
        { inherit nixpkgs; }
        // import ./network.nix flakes;

      # TODO: flake-utils.lib.eachDefaultSystem
      devShell.x86_64-linux = let
        pkgs = import nixpkgs { system = "x86_64-linux"; };
      in pkgs.mkShell {
        buildInputs = with pkgs; [
          agenix.packages.x86_64-linux.agenix
        ];
      };
    };
}
