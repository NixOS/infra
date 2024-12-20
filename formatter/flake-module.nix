{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { ... }:
    {
      treefmt = {
        # Used to find the project root
        projectRootFile = ".git/config";

        settings.global.excludes = [
          "*.age"
          "non-critical-infra/secrets/*"
        ];

        programs.actionlint.enable = true;
        programs.deno.enable = true;
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
