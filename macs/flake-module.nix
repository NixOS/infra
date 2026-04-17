{ inputs, ... }:
{
  flake.darwinConfigurations =
    let
      mkNixDarwin =
        localHostName: entrypoint:
        inputs.darwin.lib.darwinSystem {
          system = "aarch64-darwin";

          specialArgs = {
            inherit inputs;
          };

          modules = [
            {
              networking = { inherit localHostName; };
            }
            ./common.nix
            entrypoint
          ];
        };
    in
    {
      # M1 8C, 16G, 256G (Hetzner)
      enormous-catfish = mkNixDarwin "enormous-catfish" ./profiles/m1.nix;
      growing-jennet = mkNixDarwin "growing-jennet" ./profiles/m1.nix;
      intense-heron = mkNixDarwin "intense-heron" ./profiles/m1.nix;
      maximum-snail = mkNixDarwin "maximum-snail" ./profiles/m1.nix;
      sweeping-filly = mkNixDarwin "sweeping-filly" ./profiles/m1.nix;

      # M1 8C, 16G, 256G (Hosted by Flying-Circus)
      norwegian-blue = mkNixDarwin "norwegian-blue" ./profiles/m1.nix;

      # M2 8C, 24G, 1TB (Oakhost)
      eager-heisenberg = mkNixDarwin "eager-heisenberg" ./profiles/m2.large.nix;
      kind-lumiere = mkNixDarwin "kind-lumiere" ./profiles/m2.large.nix;
    }
    // inputs.nixpkgs.lib.listToAttrs (
      map
        (cfg: {
          name = cfg.hostname;
          value = inputs.darwin.lib.darwinSystem {
            system = "${cfg.system}-darwin";

            specialArgs = {
              inherit inputs;
            };

            modules = [
              ./ofborg-common.nix
              ./profiles/${cfg.profile or "ofborg-${cfg.system}"}.nix
              "${inputs.sops-nix}/modules/nix-darwin"
              { networking.hostName = cfg.hostname; }
            ];
          };
        })
        [
          # MacStadium ofborg builders
          {
            hostname = "nixos-foundation-macstadium-44911305";
            system = "x86_64";
            ip = "208.83.1.173";
            # 12 CPU cores, 32 GB RAM, 500 GB disk
          }
          {
            hostname = "nixos-foundation-macstadium-44911362";
            system = "x86_64";
            ip = "208.83.1.175";
            # 12 CPU cores, 32 GB RAM, 500 GB disk
          }
          {
            hostname = "nixos-foundation-macstadium-44911507";
            system = "x86_64";
            ip = "208.83.1.186";
            # 12 CPU cores, 32 GB RAM, 500 GB disk
          }
          {
            hostname = "nixos-foundation-macstadium-44911207";
            system = "aarch64";
            profile = "ofborg-m1";
            ip = "208.83.1.145";
            # 8 CPU cores, 16 GB RAM, 256 GB disk
          }
          {
            hostname = "nixos-foundation-macstadium-44911104";
            system = "aarch64";
            profile = "ofborg-m1";
            ip = "208.83.1.181";
            # 8 CPU cores, 16 GB RAM, 256 GB disk
          }
        ]
    );
}
