{
  edition = 201909;

  inputs.nixpkgs.uri = "nixpkgs/release-19.09";

  outputs = { self, nixpkgs, hydra }: {

    nixopsConfigurations.default =
      { inherit nixpkgs; }
      // import ./network.nix { inherit self nixpkgs hydra; };

  };
}
