{
  inputs.nixpkgs.url = "nixpkgs/nixos-20.09-small";
  inputs.nixos-channel-scripts.url = github:NixOS/nixos-channel-scripts;
  inputs.nixops.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, nix, nixops, nixos-channel-scripts }: {

    nixopsConfigurations.default =
      { inherit nixpkgs; }
      // import ./network.nix { inherit self nixpkgs nix nixops nixos-channel-scripts; };

  };
}
