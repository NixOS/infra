{
  inputs.nixpkgs.url = "nixpkgs/nixos-23.05-small";
  inputs.nix-netboot-serve.url = "github:DeterminateSystems/nix-netboot-serve";

  outputs = flakes @ { self, nixpkgs, nix-netboot-serve }:
    let inherit (nixpkgs) lib;
  in {
    nixopsConfigurations.default =
      { inherit nixpkgs; }
      // import ./network.nix flakes;

    /*
    nixosConfigurations = builtins.removeAttrs (lib.mapAttrs (name: value: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        value
        self.nixopsConfigurations.default.defaults
        {
          # hack: this doesn't check deployment options properly, but
          # is enough to have the deployment options ignored and allow
          # evaluating individual config options.
          options.deployment = lib.mkOption {
            type = (nixpkgs.legacyPackages.x86_64-linux.formats.json {}).type;
          };
        }
      ];
    }) self.nixopsConfigurations.default) ["defaults"];
    */
  };
}
