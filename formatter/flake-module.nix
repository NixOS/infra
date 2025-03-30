{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { lib, pkgs, ... }:
    {
      treefmt = {
        # Used to find the project root
        projectRootFile = ".git/config";

        settings.global.excludes = [
          "*.age"
          "non-critical-infra/secrets/*"
        ];

        # older actionlint version don't recognize aarch64 builder
        programs.actionlint.enable = lib.versionAtLeast pkgs.actionlint.version "1.7.7";
        programs.deno = {
          enable = true;
          excludes = [
            # makes these files *less* readable
            "dns/*.js"
          ];
        };
        programs.terraform.enable = true;
        programs.deadnix.enable = true;
        programs.nixfmt.enable = true;
        programs.ruff-format.enable = true;
        programs.ruff-check.enable = true;

        programs.shellcheck.enable = true;

        programs.shfmt.enable = true;
        programs.rustfmt.enable = true;
      };
    };
}
