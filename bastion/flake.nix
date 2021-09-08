{
  inputs.nixpkgs.url = "nixpkgs/nixos-21.05";
  inputs.nixos-channel-scripts.url = github:NixOS/nixos-channel-scripts/channels-cache-control;
  inputs.nixos-channel-scripts.inputs.nix.follows = "nix";
  inputs.nixos-channel-scripts.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixops.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = flakes @ { self, nixpkgs, nix, nixops, nixos-channel-scripts }: {
    nixosConfigurations.bastion = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ (import ./configuration.nix flakes) ];
    };

    nixopsConfigurations.default =
      { inherit nixpkgs; }
      // import ./network.nix flakes;

  };
}
