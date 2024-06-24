{
  description = "NixOS Infra";

  inputs = {
    nixpkgs.url = "github:NIxOS/nixpkgs";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
      };
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, git-hooks, flake-utils }:
    flake-utils.lib.eachSystem [ "aarch64-linux" "x86_64-linux" ] (system: {
      checks = {
        pre-commit = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            deadnix.enable = true;
            statix.enable = true;
          };
        };
      };
      devShells.default = nixpkgs.legacyPackages.${system}.mkShell {
        buildInputs = self.checks.${system}.pre-commit.enabledPackages;
        inherit (self.checks.${system}.pre-commit) shellHook;
      };
    }
  );
}
