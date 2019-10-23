{
  edition = 201909;

  inputs.nixpkgs.uri = "nixpkgs/release-19.09";
  #inputs.nixops.uri = "/home/deploy/src/nixops";

  outputs = { self, nixpkgs, nix, nixops }: {

    nixopsConfigurations.default =
      { inherit nixpkgs; }
      // import ./network.nix { inherit self nix nixops; };

  };
}
