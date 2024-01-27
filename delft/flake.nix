{
  inputs.nixpkgs.url = "nixpkgs/nixos-23.05-small";
  inputs.nix-netboot-serve.url = "github:DeterminateSystems/nix-netboot-serve";

  inputs.agenix = {
    url = "github:ryantm/agenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = flakes @ { self, agenix, nixpkgs, nix-netboot-serve }:
    let inherit (nixpkgs) lib;
  in {
    nixosConfigurations.eris = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./eris.nix
        ./eris-physical.nix
        agenix.nixosModules.age
        nix-netboot-serve.nixosModules.nix-netboot-serve
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
