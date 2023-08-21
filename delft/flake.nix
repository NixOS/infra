{
  #inputs.nixpkgs.url = "/home/deploy/src/edolstra-nixpkgs"; # toString ../../edolstra-nixpkgs; # = "nixpkgs/release-19.09";
  inputs.nixpkgs.url = "nixpkgs/nixos-22.05-small";
  inputs.nix.follows = "hydra/nix";
  inputs.hydra.url = "github:NixOS/hydra/lazy-trees";
  inputs.nix-netboot-serve.url = "github:DeterminateSystems/nix-netboot-serve";
  inputs.hydra-scale-equinix-metal.url = "github:DeterminateSystems/hydra-scale-equinix-metal";
  #inputs.hydra.url = "github:DeterminateSystems/hydra/queue-runner-exporter";

  outputs = flakes @ { self, nixpkgs, nix, hydra, nix-netboot-serve, hydra-scale-equinix-metal /*, dwarffs */ }:
    let inherit (nixpkgs) lib;
  in {
    nixopsConfigurations.default =
      { inherit nixpkgs; }
      // import ./network.nix flakes;

    /*
    nixosConfigurations = builtins.removeAttrs (lib.mapAttrs (name: value: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        value
        self.nixopsConfigurations.default.defaults
        {
          # hack: this doesn't check deployment options properly, but
          # is enough to have the deployment options ignored and allow
          # evaluating individual config options.
          options.deployment = lib.mkOption {
            type = (nixpkgs.legacyPackages.x86_64-linux.formats.json {}).type;
          };
        }
      ];
    }) self.nixopsConfigurations.default) ["defaults"];
    */

    nixosConfigurations.rhea = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        self.nixosModules.common
        ./rhea
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
  };
}
