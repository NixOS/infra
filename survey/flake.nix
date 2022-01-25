{
  inputs.nixpkgs.url = "nixpkgs/nixos-21.11";

  outputs = flakes @ { self, nixpkgs }: {
    nixosConfigurations.survey = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ (import ./configuration.nix flakes) ];
    };

    devShell.x86_64-linux =
      with nixpkgs.legacyPackages.x86_64-linux;
      mkShell {
        nativeBuildInputs = [
          awscli
          (terraform_0_15.withPlugins (p: with p; [ aws p.null external tls local ]))
        ];

        shellHook = ''
          alias tf=terraform
        '';
      };
  };
}
