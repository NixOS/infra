{ inputs, ... }:
{
  flake.darwinConfigurations =
    let
      mkNixDarwin =
        hostname: entrypoint: args:
        inputs.darwin.lib.darwinSystem {
          system = args.system or "aarch64-darwin";

          specialArgs = {
            inherit inputs;
          };

          modules = [
            {
              networking = {
                # the name used to resolve the flake output
                localHostName = hostname;
                # the name that propagates into the MDM
                computerName = hostname;
              };

              system.stateVersion = 5;
            }
            entrypoint
          ]
          ++ (args.extraModules or [ ]);
        };
    in
    {
      bootstrap = mkNixDarwin "bootstrap" ./profiles/bootstrap.nix { };

      # M1 8C, 16G, 256G (Hetzner)
      enormous-catfish = mkNixDarwin "enormous-catfish" ./profiles/m1.nix { };
      growing-jennet = mkNixDarwin "growing-jennet" ./profiles/m1.nix { };
      intense-heron = mkNixDarwin "intense-heron" ./profiles/m1.nix { };
      maximum-snail = mkNixDarwin "maximum-snail" ./profiles/m1.nix { };
      sweeping-filly = mkNixDarwin "sweeping-filly" ./profiles/m1.nix { };

      # M1 8C, 16G, 256G (Hosted by Flying-Circus)
      norwegian-blue = mkNixDarwin "norwegian-blue" ./profiles/m1.nix { };

      # M2 8C, 24G, 1TB (Oakhost)
      eager-heisenberg = mkNixDarwin "eager-heisenberg" ./profiles/m2.large.nix { };
      kind-lumiere = mkNixDarwin "kind-lumiere" ./profiles/m2.large.nix { };

      # x86_64, 12C, 32GB, 500G (Macstadium)
      # 12 CPU cores, 32 GB RAM, 500 GB disk
      "mac01.ofborg.org" = mkNixDarwin "mac01.ofborg.org" ./profiles/ofborg-x86_64.nix {
        system = "x86_64-darwin";
        extraModules = [
          "${inputs.sops-nix}/modules/nix-darwin"
          { networking.hostName = "nixos-foundation-macstadium-44911305"; }
        ];
      }; # nixos-foundation-macstadium-44911305
      "mac02.ofborg.org" = mkNixDarwin "mac02.ofborg.org" ./profiles/ofborg-x86_64.nix {
        system = "x86_64-darwin";
        extraModules = [
          "${inputs.sops-nix}/modules/nix-darwin"
          { networking.hostName = "nixos-foundation-macstadium-44911362"; }
        ];
      }; # nixos-foundation-macstadium-44911362
      "mac03.ofborg.org" = mkNixDarwin "mac03.ofborg.org" ./profiles/ofborg-x86_64.nix {
        system = "x86_64-darwin";
        extraModules = [
          "${inputs.sops-nix}/modules/nix-darwin"
          { networking.hostName = "nixos-foundation-macstadium-44911507"; }
        ];
      }; # nixos-foundation-macstadium-44911507

      # M1 8C, 16G, 256M (Macstadium)
      "mac04.ofborg.org" = mkNixDarwin "mac04.ofborg.org" ./profiles/ofborg-m1.nix {
        extraModules = [
          "${inputs.sops-nix}/modules/nix-darwin"
          { networking.hostName = "nixos-foundation-macstadium-44911207"; }
        ];
      }; # nixos-foundation-macstadium-44911207
      "mac05.ofborg.org" = mkNixDarwin "mac05.ofborg.org" ./profiles/ofborg-m1.nix {
        extraModules = [
          "${inputs.sops-nix}/modules/nix-darwin"
          { networking.hostName = "nixos-foundation-macstadium-44911104"; }
        ];
      }; # nixos-foundation-macstadium-44911104
    };
}
