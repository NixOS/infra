{
  description = "A very basic flake";

  outputs = { self, nixpkgs, systems }:
    let
      eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system:
        f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = eachSystem (pkgs:
        let
          peribolos = pkgs.callPackage ./peribolos.nix { };
        in
        {
          default = pkgs.mkShell {
            packages = [ peribolos ];
          };
        });
    };
}
