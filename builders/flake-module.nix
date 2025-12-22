{ inputs, ... }:
{
  flake.nixosConfigurations =
    let
      mkNixOS =
        system: config:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = { inherit inputs; };

          modules = [
            inputs.agenix.nixosModules.age
            inputs.disko.nixosModules.disko

            ./common/hardening.nix
            ./common/network.nix
            ./common/nix.nix
            ./common/node-exporter.nix
            ./common/hydra-queue-builder.nix
            ./common/system.nix
            ./common/tools.nix
            ./common/update.nix
            ./common/users.nix
            ./common/ssh.nix

            ../modules/rasdaemon.nix

            config
          ];
        };
    in
    {
      # Epyc 9454P (48C/96T), 256 GB DDR4 RAM, 2x 1.92TB PCIe4 NVME
      elated-minsky = mkNixOS "x86_64-linux" ./instances/elated-minsky.nix;
      sleepy-brown = mkNixOS "x86_64-linux" ./instances/sleepy-brown.nix;

      # Ampere Q80-30 (80C), 256 GB DDR4 RAM, 2x3.84TB PCIe4 NVME
      goofy-hopcroft = mkNixOS "aarch64-linux" ./instances/goofy-hopcroft.nix;

      # Ampere Q80-30 (80C), 128 GB DDR4 RAM, 2x960GB PCIe4 NVME
      hopeful-rivest = mkNixOS "aarch64-linux" ./instances/hopeful-rivest.nix;
    };

  perSystem =
    { pkgs, inputs', ... }:
    {
      devShells.builders = pkgs.mkShell {
        buildInputs = [
          inputs'.agenix.packages.agenix
        ];
      };
    };
}
