{
  inputs,
  lib,
  ...
}:
let
  flakesModule = {
    imports = [
      inputs.agenix.nixosModules.age
      inputs.disko.nixosModules.disko
      inputs.hydra.nixosModules.hydra
    ];

    nixpkgs.overlays = [
      inputs.nix.overlays.default
      inputs.hydra.overlays.default
      inputs.nixos-channel-scripts.overlays.default
      inputs.rfc39.overlays.default
    ];
  };
in
{
  imports = [
    ./colmena.nix
  ];
  colmena.hosts = {
    haumea = { };
    pluto = { };
    mimas = { };
  };

  flake = {
    nixosConfigurations.haumea = lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        flakesModule
        ./haumea
      ];
    };

    nixosConfigurations.pluto = lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        flakesModule
        ./pluto
      ];
    };

    nixosConfigurations.mimas = lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        flakesModule
        ./mimas
      ];
    };
  };

  perSystem =
    { pkgs, inputs', ... }:
    {
      devShells.build = pkgs.mkShell {
        buildInputs = [
          inputs'.agenix.packages.agenix
          inputs'.colmena.packages.colmena
        ];
      };
    };
}
