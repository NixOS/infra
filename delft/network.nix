flakes:

let
  networkoverlay = self: super: {
    prometheus-postgres-exporter = self.callPackage ./prometheus/postgres-exporter.nix { };
  };
in
{
  defaults = {
    documentation.nixos.enable = false;

    security.acme.acceptTerms = true;
    security.acme.defaults.email = "webmaster@nixos.org";

    imports = [
      ../modules/wireguard.nix
      ../modules/prometheus
      # flakes.dwarffs.nixosModules.dwarffs # broken by Nix 2.6
      {
        system.configurationRevision = flakes.self.rev
          or (throw "Cannot deploy from an unclean source tree!");
        nixpkgs.overlays = [
          flakes.nix.overlays.default
          networkoverlay
        ];
        nix.registry.nixpkgs.flake = flakes.nixpkgs;
        nix.nixPath = [ "nixpkgs=${flakes.nixpkgs}" ];
      }
    ];
  };

  eris = import ./eris.nix;

  haumea = {
    imports = [ ./haumea.nix ];
  };

  rhea = {
    imports = [
      ./rhea
      flakes.hydra.nixosModules.hydra
    ];
  };
}
