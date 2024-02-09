{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11-small";
  inputs.nix-netboot-serve.url = "github:DeterminateSystems/nix-netboot-serve";

  inputs.rfc39.url = "github:NixOS/rfc39";
  inputs.rfc39.inputs.nixpkgs.follows = "nixpkgs";

  inputs.agenix = {
    url = "github:ryantm/agenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = flakes @ { self, agenix, nixpkgs, nix-netboot-serve, rfc39 }:
    let
      inherit (nixpkgs) lib;

      flakesModule = {
        imports = [
          agenix.nixosModules.age
          nix-netboot-serve.nixosModules.nix-netboot-serve
        ];

        nixpkgs.overlays = [
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
