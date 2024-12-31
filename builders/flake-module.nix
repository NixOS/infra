{ inputs, ... }:
{
  flake.nixosConfigurations =
    let
      mkNixOS =
        system: config:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            inputs.disko.nixosModules.disko

            ./common/hardening.nix
            ./common/network.nix
            ./common/nix.nix
            ./common/node-exporter.nix
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
    };
}
