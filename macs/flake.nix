{
  description = "nixos-org-configurations macs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin = { url = "github:LnL7/nix-darwin"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs =
    { nixpkgs
    , darwin
    , ...
    }@inputs:
    {
      darwinConfigurations =
        let
          mac = system: darwin.lib.darwinSystem {
            inherit system;

            modules = [
              ./nix-darwin.nix
            ];
          };
        in
        {
          arm64 = mac "aarch64-darwin";
          x86_64 = mac "x86_64-darwin";
        };
    };
}
