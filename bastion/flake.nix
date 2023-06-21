{
  inputs.nixpkgs.url = "nixpkgs/nixos-22.11";
  inputs.nixops.url = "github:NixOS/nixops/flake-support";
  inputs.nixos-channel-scripts.url = "github:K900/nixos-channel-scripts/the-nix-index-thing";
  inputs.nixos-channel-scripts.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = flakes @ { self, nixpkgs, nix, nixops, nixos-channel-scripts }: {
    nixosConfigurations.bastion = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ (import ./configuration.nix flakes) ];
    };

    devShell.x86_64-linux =
      with nixpkgs.legacyPackages.x86_64-linux;
      mkShell {
        nativeBuildInputs = [
          awscli
          (terraform.withPlugins (p: with p; [ aws p.null external ]))
        ];

        shellHook = ''
          alias tf=terraform
        '';
      };
  };
}
