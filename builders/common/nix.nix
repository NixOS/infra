{
  config,
  pkgs,
  ...
}:

{
  nix = {
    package = pkgs.lix;
    nrBuildUsers = config.nix.settings.max-jobs + 32;

    gc =
      let
        maxFreed = 100; # GB
      in
      {
        automatic = true;
        dates = "*:0/30"; # every 30 minutes
        options = "--max-freed \"$((${toString maxFreed} * 1024**3 - 1024 * $(df --output=avail /nix/store | tail -n 1)))\"";
      };

    settings = {
      builders-use-substitutes = true;
      extra-experimental-features = [
        "cgroups"
        "nix-command"
        "no-url-literals"
        "flakes"
      ];
      system-features = [
        "kvm"
        "nixos-test"
      ];
      trusted-users = [
        "build"
        "root"
      ];
      use-cgroups = true;
    };
  };
}