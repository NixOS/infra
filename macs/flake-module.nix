{ inputs, ... }:
{
  flake.darwinConfigurations =
    let
      mac =
        system: entrypoint:
        inputs.darwin.lib.darwinSystem {
          inherit system;

          modules = [
            ./common.nix
            entrypoint
          ];
        };
    in
    {
      m1 = mac "aarch64-darwin" ./profiles/m1.nix;
      m2-large = mac "aarch64-darwin" ./profiles/m2.large.nix;
    };
}
