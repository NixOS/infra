{ ... }:
{
  perSystem =
    { self', lib, ... }:
    {
      checks =
        let
          # TODO: our CI doesn't have a enough space for these just now
          #nixosMachines = lib.mapAttrs' (
          #  name: config: lib.nameValuePair "nixos-${name}" config.config.system.build.toplevel
          #) ((lib.filterAttrs (_: config: config.pkgs.system == system)) self.nixosConfigurations);
          nixosMachines = { };

          packages = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") self'.packages;
          devShells = lib.mapAttrs' (n: lib.nameValuePair "devShell-${n}") self'.devShells;
        in
        nixosMachines // packages // devShells;
    };
}
