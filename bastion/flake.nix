{
  edition = 201909;

  inputs.nixpkgs.url = "nixpkgs/release-19.09";
  #inputs.nixops.uri = "/home/deploy/src/nixops";

  inputs.nixos-channel-scripts.url = github:NixOS/nixos-channel-scripts;

  outputs = { self, nixpkgs, nix, nixops, nixos-channel-scripts }: {

    nixopsConfigurations.default =
      { inherit nixpkgs; }
      // import ./network.nix { inherit self nix nixops nixos-channel-scripts; };

  };
}
