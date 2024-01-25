{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11-small";
  inputs.nix.follows = "hydra/nix";
  inputs.hydra.url = "github:NixOS/hydra";
  inputs.hydra-scale-equinix-metal.url = "github:DeterminateSystems/hydra-scale-equinix-metal";

  outputs = flakes @ { self, nixpkgs, nix, hydra, hydra-scale-equinix-metal }: {
    nixosConfigurations.rhea = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        self.nixosModules.common
        ./configuration.nix
        hydra.nixosModules.hydra
        hydra-scale-equinix-metal.nixosModules.default
      ];
    };

    nixosModules.common =
      { config, pkgs, lib, ... }:
      {
        system.configurationRevision = self.rev
          or (throw "Cannot deploy from an unclean source tree!");
        #nix.registry.nixpkgs.flake = nixpkgs;
        #nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
        nixpkgs.overlays = [
          nix.overlays.default
        ];
      };

    devShell.x86_64-linux =
      with nixpkgs.legacyPackages.x86_64-linux;
      mkShell {
        nativeBuildInputs = [
          (terraform.withPlugins (p: with p; [ aws p.null external ]))
        ];

        shellHook = ''
          alias tf=terraform
        '';
      };
  };
}
