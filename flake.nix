{
  description = "Nixos org infra";

  nixConfig.extra-substituters = [ "https://nixos-infra-dev.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [
    "nixos-infra-dev.cachix.org-1:OvwhqPPs81cInrtRAX0K7dG6lw8wXcQEX4xyp4AnSXw="
  ];

  inputs = {
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    hydra.url = "github:NixOS/hydra";
    hydra.inputs.nixpkgs.follows = "nixpkgs";
    nix.follows = "hydra/nix";

    #nixos-channel-scripts.url = "github:NixOS/nixos-channel-scripts";
    nixos-channel-scripts.url = "github:obsidiansystems/nixos-channel-scripts/nix-2.28";
    nixos-channel-scripts.inputs.nixpkgs.follows = "nixpkgs";

    rfc39.url = "github:NixOS/rfc39";
    rfc39.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11-small";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        stable.follows = "nixpkgs";
      };
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    srvos = {
      url = "github:numtide/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    first-time-contribution-tagger = {
      url = "github:Janik-Haag/first-time-contribution-tagger";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };
  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      imports = [
        ./build/flake-module.nix
        ./builders/flake-module.nix
        ./dns/flake-module.nix
        ./formatter/flake-module.nix
        ./checks/flake-module.nix
        ./terraform/flake-module.nix
        ./non-critical-infra/flake-module.nix
        ./macs/flake-module.nix
      ];
    };
}
