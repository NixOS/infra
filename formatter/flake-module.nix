{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        # Used to find the project root
        projectRootFile = ".git/config";

        programs.terraform.enable = true;
        programs.deadnix.enable = true;
        programs.nixfmt.enable = true;
        programs.nixfmt.package = pkgs.nixfmt-rfc-style;
        programs.ruff-format.enable = true;

        programs.shellcheck.enable = true;

        programs.shfmt.enable = true;
        programs.rustfmt.enable = true;
      };
    };
}
