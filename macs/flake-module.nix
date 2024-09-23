{ inputs, ... }:
{
  flake.darwinConfigurations =
    let
      mac =
        system:
        inputs.darwin.lib.darwinSystem {
          inherit system;

          modules = [ ./nix-darwin.nix ];
        };
    in
    {
      arm64 = mac "aarch64-darwin";
      x86_64 = mac "x86_64-darwin";
    };
}
