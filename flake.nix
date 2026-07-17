{
  description = "NixOS.org infra";

  nixConfig.extra-substituters = [ "https://nixos-infra-dev.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [
    "nixos-infra-dev.cachix.org-1:OvwhqPPs81cInrtRAX0K7dG6lw8wXcQEX4xyp4AnSXw="
  ];

  inputs = {
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ai-robots-txt.url = "https://github.com/ai-robots-txt/ai.robots.txt/raw/refs/heads/main/robots.json";
    ai-robots-txt.flake = false;

    fast-nix-gc.url = "github:Mic92/fast-nix-gc";
    fast-nix-gc.inputs.nixpkgs.follows = "nixpkgs";
    fast-nix-gc.inputs.nix-darwin.follows = "darwin";
    fast-nix-gc.inputs.treefmt-nix.follows = "treefmt-nix";

    # This is https://github.com/P3TERX/GeoLite.mmdb
    # Atlernative https://github.com/sapics/ip-location-db
    geolite2-asn-mmdb.url = "https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-ASN.mmdb";
    geolite2-asn-mmdb.flake = false;

    hydra = {
      url = "github:NixOS/hydra";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    nix-index = {
      url = "github:nix-community/nix-index";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixocaine.url = "git+https://git.madhouse-project.org/iocaine/nixocaine";
    nixocaine.inputs.nixpkgs.follows = "nixpkgs";

    rfc39 = {
      url = "github:NixOS/rfc39";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05-small";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    freescout = {
      url = "git+https://cyberchaos.dev/e1mo/freescout-nix-flake.git";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

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

    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-swh = {
      url = "github:nix-community/nixpkgs-swh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ofborg = {
      url = "github:NixOS/ofborg";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ofborg-viewer = {
      url = "github:NixOS/ofborg-viewer";
      flake = false;
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
