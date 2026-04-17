{ self, lib, ... }:
{
  # Group machine toplevels by architecture so CI can build all hosts of one
  # arch in a single nix-fast-build invocation (the ofborg fleet in particular
  # shares almost its entire closure). Hosts are listed explicitly to avoid
  # forcing evaluation of every configuration just to learn its system.
  flake.ciSystems =
    let
      nixos = names: lib.genAttrs names (n: self.nixosConfigurations.${n}.config.system.build.toplevel);
      darwin = names: lib.genAttrs names (n: self.darwinConfigurations.${n}.config.system.build.toplevel);
    in
    {
      ofborg-x86_64-linux = nixos [
        "core01.ofborg.org"
        "build01.ofborg.org"
        "build02.ofborg.org"
        "build03.ofborg.org"
        "build04.ofborg.org"
      ];
      ofborg-aarch64-linux = nixos [
        "eval01.ofborg.org"
        "eval02.ofborg.org"
        "eval03.ofborg.org"
        "eval04.ofborg.org"
        "build05.ofborg.org"
      ];
      ofborg-aarch64-darwin = darwin [
        "nixos-foundation-macstadium-44911207"
        "nixos-foundation-macstadium-44911104"
      ];
      ofborg-x86_64-darwin = darwin [
        "nixos-foundation-macstadium-44911305"
        "nixos-foundation-macstadium-44911362"
        "nixos-foundation-macstadium-44911507"
      ];
    };

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
