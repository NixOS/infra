{
  edition = 201909;

  inputs.nixpkgs.url = "nixpkgs/release-19.09";
  #inputs.nixops.url = "/home/deploy/src/nixops";
  inputs.nixos-channel-scripts.url = github:NixOS/nixos-channel-scripts;
  inputs.nix.url = github:NixOS/nix/cfc38257cfcdabd34151d723906b38873e7ef6d0;

  outputs = { self, nixpkgs, nix, nixops, nixos-channel-scripts }: {

    nixopsConfigurations.default =
      { inherit nixpkgs; }
      // import ./network.nix { inherit self nix nixops nixos-channel-scripts; };

  };
}
