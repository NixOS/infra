{
  edition = 201909;

  #inputs.nixpkgs.uri = "/home/deploy/src/edolstra-nixpkgs"; # toString ../../edolstra-nixpkgs; # = "nixpkgs/release-19.09";
  inputs.nixpkgs.uri = "nixpkgs/release-19.09";

  outputs = flakes @ { self, nixpkgs, hydra }: {

    nixopsConfigurations.default =
      { inherit nixpkgs; }
      // import ./network.nix { inherit self nixpkgs hydra flakes; };

  };
}
