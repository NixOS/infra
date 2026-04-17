{ inputs, ... }:
{
  imports = [
    inputs.srvos.nixosModules.server
    ../../../modules/common.nix
    ../common.nix
    ./ofborg-config.nix
  ];

  nix.gc.automatic = true;

  # TODO wire up exporters
  # TODO loki

  # Not part of the infra team
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM35Bq87SBWrEcoDqrZFOXyAmV/PJrSSu3hl3TdVvo4C janne"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPK/3rYhlIzoPCsPK38PMdK1ivqPaJgUqWwRtmxdKZrO ✏️"
  ];

  nixpkgs.overlays = [
    (_self: super: {
      ofborg = inputs.ofborg.packages.${super.stdenv.hostPlatform.system}.pkg;
    })
  ];

  systemd.targets.ofborg = {
    description = "ofBorg target";
    wantedBy = [ "multi-user.target" ];
  };

  deployment.tags = [ "ofborg" ];
}
