let
  hostpkgs = import <nixpkgs> {};

  importJSON = file:
    let
      srcAttrs = builtins.fromJSON (builtins.readFile file);
      src = hostpkgs.fetchgit {
        inherit (srcAttrs) url rev sha256;
      };
    in import src;

  nixpkgs = importJSON ./nix/nixpkgs.json {};
  darwin = importJSON ./nix/nix-darwin.json {
    nixpkgs = nixpkgs.path;
    configuration = ./configuration.nix;
    system = "x86_64-darwin";
  };
in darwin
