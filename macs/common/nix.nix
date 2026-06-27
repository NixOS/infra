{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.fast-nix-gc.darwinModules.default
  ];

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
  };

  services.fast-nix-gc = {
    enable = true;
    automatic = true;
    startCalendarInterval = [
      {
        Minute = 15;
      }
    ];
  };

}
