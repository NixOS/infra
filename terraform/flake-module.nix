let
  convert2Tofu =
    provider:
    provider.override (prev: {
      homepage =
        builtins.replaceStrings
          [ "registry.terraform.io/providers" ]
          [
            "registry.opentofu.org"
          ]
          prev.homepage;
    });
in
{
  perSystem =
    { pkgs, ... }:
    {
      devShells.terraform = pkgs.mkShellNoCC {
        packages = [
          pkgs.awscli2
          # TODO: migrate registry for opentofu as well.
          (pkgs.opentofu.withPlugins (
            p:
            builtins.map convert2Tofu [
              p.hashicorp_aws
              p.fastly_fastly
              p.aegirhealth_netlify
              p.numtide_secret
            ]
          ))
        ];
      };

      # get rid of this, once we fix the migration above.
      devShells.terraform-iam = pkgs.mkShellNoCC {
        packages = [
          pkgs.awscli2
          (pkgs.opentofu.withPlugins (
            p:
            builtins.map convert2Tofu [
              p.hashicorp_aws
              p.fastly_fastly
              p.aegirhealth_netlify
              p.numtide_secret
            ]
          ))
        ];
      };
    };
}
