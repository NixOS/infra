{
  config,
  lib,
  pkgs,
  ...
}:

{
  nix = {
    package = pkgs.nix;
    nrBuildUsers = config.nix.settings.max-jobs + 32;

    gc =
      let
        maxFreed = 500; # GB
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
        "no-url-literals"
        "flakes"
      ];
      system-features = [
        "kvm"
        "nixos-test"
        "benchmark" # we may restrict this in the central /etc/nix/machines anyway
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
        "/tmp"
        "-maxdepth 1"
        "-type d"
        "-iname \"nix-build-*\""
        "-mtime +1" # days
        "-exec rm -rf {} +"
      ];
    };
  };
}
