{
  inputs.nixpkgs.url = "nixpkgs/nixos-23.05-small";
  inputs.nix-netboot-serve.url = "github:DeterminateSystems/nix-netboot-serve";

  outputs = flakes @ { self, nixpkgs, nix-netboot-serve }:
    let inherit (nixpkgs) lib;
  in {
    nixosConfigurations.eris = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./eris.nix
        ./eris-physical.nix
        flakes.nix-netboot-serve.nixosModules.nix-netboot-serve
      ];
    };

    nixosConfigurations.haumea = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./haumea.nix
        ./haumea-physical.nix
      ];
    };

    nixopsConfigurations.default =
      { inherit nixpkgs; }
      // import ./network.nix flakes;
  };
}
