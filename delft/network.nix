flakes:

let
in
{
  defaults = {
    imports = [
      # flakes.dwarffs.nixosModules.dwarffs # broken by Nix 2.6
      {
      }
    ];
  };

  eris = {
    imports = [
      ./eris.nix
      flakes.nix-netboot-serve.nixosModules.nix-netboot-serve
    ];
  };

  haumea = {
    imports = [ ./haumea.nix ];
  };
}
