{
  config,
  pkgs,
  ...
}:

{
  nix = {
    # Used because Nix had a weird random segfault and using Lix was the easiest solution to get the builds going
    # TODO: Try to reproduce the crashes to generate a proper issue or fix in Nix.
    package = pkgs.lix;
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
        "benchmark" # we may restrict this in the central /etc/nix/machines anyway
      ];
      trusted-users = [
        "build"
        "root"
      ];
      use-cgroups = true;
      max-silent-time = 7200; # 2h
    };
  };
}
