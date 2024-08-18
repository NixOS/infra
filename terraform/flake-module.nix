let
  convert2Tofu =
    provider:
    provider.override (prev: {
      homepage = builtins.replaceStrings [ "registry.terraform.io/providers" ] [
        "registry.opentofu.org"
      ] prev.homepage;
    });
in
{
  perSystem =
    { pkgs, ... }:
    {
      devShells.terraform = pkgs.mkShellNoCC {
        packages = [
          pkgs.awscli2
          (pkgs.opentofu.withPlugins (
            p:
            builtins.map convert2Tofu [
              p.aws
              p.fastly
              p.netlify
              p.secret
            ]
            ++ [
              # FIXME: for our `terraform` target our state file still uses the old registry prefix
              p.aws
              p.fastly
              p.netlify
              p.secret
            ]
          ))
        ];
      };
    };
}
