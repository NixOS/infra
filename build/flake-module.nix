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
    ];

    nixpkgs.overlays = [
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

      specialArgs = { inherit inputs; };
      modules = [
        flakesModule
        ./haumea
      ];
    };

    nixosConfigurations.pluto = lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = { inherit inputs; };
      modules = [
        flakesModule
        ./pluto
      ];
    };

    nixosConfigurations.mimas = lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = { inherit inputs; };
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
