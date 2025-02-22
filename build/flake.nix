{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11-small";

  inputs.agenix.url = "github:ryantm/agenix";
  inputs.agenix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.colmena.url = "github:zhaofengli/colmena";
  inputs.colmena.inputs.nixpkgs.follows = "nixpkgs";

  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix-eval-jobs.url = "github:nix-community/nix-eval-jobs";
  inputs.nix-eval-jobs.inputs.nixpkgs.follows = "nixpkgs";

  inputs.hydra.url = "github:NixOS/hydra/hydra.nixos.org";
  inputs.hydra.inputs.nixpkgs.follows = "nixpkgs";
  inputs.hydra.inputs.nix-eval-jobs.follows = "nix-eval-jobs";
  inputs.nix.follows = "hydra/nix";

  inputs.nixos-channel-scripts.url = "github:NixOS/nixos-channel-scripts";
  inputs.nixos-channel-scripts.inputs.nixpkgs.follows = "nixpkgs";

  inputs.rfc39.url = "github:NixOS/rfc39";
  inputs.rfc39.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    {
      self,
      agenix,
      colmena,
      disko,
      hydra,
      nix,
      nixpkgs,
      nixos-channel-scripts,
      rfc39,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      flakesModule = {
        imports = [
          agenix.nixosModules.age
          disko.nixosModules.disko
          hydra.nixosModules.hydra
        ];

        nixpkgs.overlays = [
          nix.overlays.default
          hydra.overlays.default
          nixos-channel-scripts.overlays.default
          rfc39.overlays.default
        ];
      };
    in
    {
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

      nixosConfigurations.mimas = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          flakesModule
          ./mimas
        ];
      };

      colmena =
        {
          meta = {
            description = "NixOS.org infrastructure";
            nixpkgs = import nixpkgs { system = "x86_64-linux"; };
          };
        }
        // builtins.mapAttrs (name: value: {
          nixpkgs.system = value.config.nixpkgs.system;
          imports = value._module.args.modules;
          deployment = {
            targetHost = "${name}.nixos.org";
          };
        }) self.nixosConfigurations;

      devShells =
        nixpkgs.lib.genAttrs
          [
            "aarch64-linux"
            "aarch64-darwin"
            "x86_64-linux"
            "x86_64-darwin"
          ]
          (system: {
            default =
              let
                pkgs = nixpkgs.legacyPackages.${system};
              in
              pkgs.mkShell {
                buildInputs = [
                  agenix.packages.${system}.agenix
                  colmena.packages.${system}.colmena
                ];
              };
          });
    };
}
