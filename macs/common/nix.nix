{
  config,
  pkgs,
  ...
}:

{
  environment.systemPackages = [
    config.nix.package
  ];

  nix = {
    # Backport of NixOS/nix#15992: a temp root registered while a GC is in its
    # deletion phase was ignored, so per-build AddTempRoot pins raced the
    # periodic GC and inputs/outputs were collected mid-build (NixOS/hydra#1806).
    package = pkgs.nix.appendPatches [ ../../builders/common/nix-gc-addtemproot-race.patch ];

    settings = {
      extra-experimental-features = [
        "nix-command"
        "flakes"
      ];
      max-silent-time = 7200; # 2h
      timeout = 43200; # 12h
    };
    gc = {
      automatic = true;
      interval = [
        {
          Minute = 15;
        }
        {
          Minute = 45;
        }
      ];
      # ensure up to 100G free space every half hour
      options = "--max-freed $(df -k /nix/store | awk 'NR==2 {available=$4; required=100*1024*1024; to_free=required-available; printf \"%.0d\", to_free*1024}')";
    };
  };
}
