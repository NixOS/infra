{ inputs, ... }:
{
  flake.darwinConfigurations =
    let
      mkNixDarwin =
        localHostName: entrypoint:
        inputs.darwin.lib.darwinSystem {
          system = "aarch64-darwin";

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

      # M2 8C, 24G, 1TB (Oakhost)
      eager-heisenberg = mkNixDarwin "eager-heisenberg" ./profiles/m2.large.nix;
      kind-lumiere = mkNixDarwin "kind-lumiere" ./profiles/m2.large.nix;
    };
}
