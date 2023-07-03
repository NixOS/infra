{
  inputs = {
    nixpkgs.url = "nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = flakes @ { self, nixpkgs, flake-utils }:

    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells = {
       default = with pkgs;
        mkShell {
          buildInputs = [
            jq
            (terraform.withPlugins (p: with p; [
              aws
            ]))
          ];
        };
      };
    });
}
