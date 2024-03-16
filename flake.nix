{
  description = "NixOS Infra";

  inputs = {
    nixpkgs.url = "github:NIxOS/nixpkgs";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, pre-commit-hooks, flake-utils }:
    flake-utils.lib.eachSystem [ "aarch64-linux" "x86_64-linux" ] (system: {
      checks = {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            deadnix.enable = true;
            statix.enable = true;
          };
        };
      };
      devShells.default = nixpkgs.legacyPackages.${system}.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
      };
    }
  );
}
