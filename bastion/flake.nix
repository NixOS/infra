{
  edition = 201909;

  inputs.nixpkgs.url = "nixpkgs/nixos-20.03-small";
  inputs.nixos-channel-scripts.url = github:NixOS/nixos-channel-scripts;
  inputs.nixops.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, nix, nixops, nixos-channel-scripts }: {

    nixopsConfigurations.default =
      { inherit nixpkgs; }
      // import ./network.nix { inherit self nix nixops nixos-channel-scripts; };

  };
}
