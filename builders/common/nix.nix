{
  config,
  lib,
  pkgs,
  ...
}:

{
  nix = {
    # Backport of NixOS/nix#15992: a temp root registered while a GC is in its
    # deletion phase was ignored, so hydra-builder's per-build AddTempRoot pins
    # raced the hourly GC and inputs/outputs were collected mid-build
    # (NixOS/hydra#1806).
    package = pkgs.nix.appendPatches [ ./nix-gc-addtemproot-race.patch ];
    nrBuildUsers = config.nix.settings.max-jobs + 32;

    gc =
      let
        maxFreed = 800; # GB
      in
      {
        automatic = true;
        dates = "hourly";
        options = "--max-freed \"$((${toString maxFreed} * 1024**3 - 1024 * $(df --output=avail /nix/store | tail -n 1)))\"";
      };

    settings = {
      accept-flake-config = false;
      builders-use-substitutes = true;
      extra-experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "build"
        "root"
      ];
      max-silent-time = 10800; # 3h
    };
  };

  systemd.services.prune-stale-nix-builds = {
    description = "Prune stale nix build roots";
    startAt = "hourly";
    unitConfig.Documentation = "https://github.com/NixOS/nix/issues/5207";
    serviceConfig = {
      ExecStart = lib.concatStringsSep " " [
        (lib.getExe pkgs.findutils)
        "/nix/var/nix/builds"
        "-mindepth 1"
        "-maxdepth 1"
        "-type d"
        "-mtime +1" # days
        "-exec rm -rf {} +"
      ];
    };
  };
}
