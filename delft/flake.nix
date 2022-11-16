{
  #inputs.nixpkgs.url = "/home/deploy/src/edolstra-nixpkgs"; # toString ../../edolstra-nixpkgs; # = "nixpkgs/release-19.09";
  inputs.nixpkgs.url = "nixpkgs/nixos-22.05-small";
  inputs.nix.follows = "hydra/nix";
  inputs.hydra.url = "github:NixOS/hydra/lazy-trees";
  inputs.nix-netboot-serve.url = "github:DeterminateSystems/nix-netboot-serve";
  #inputs.hydra.url = "github:DeterminateSystems/hydra/queue-runner-exporter";
  outputs = flakes @ { self, nixpkgs, nix, hydra, nix-netboot-serve /*, dwarffs */ }: {
    nixopsConfigurations.default =
      { inherit nixpkgs; }
      // import ./network.nix flakes;

  };
}
