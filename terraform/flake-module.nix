{
  perSystem =
    { pkgs, ... }:
    {
      devShells.terraform = pkgs.mkShellNoCC {
        packages = [
          pkgs.awscli2
          (pkgs.opentofu.withPlugins (
            plugin: with plugin; [
              hashicorp_aws
              fastly_fastly
              aegirhealth_netlify
              numtide_secret
            ]
          ))
        ];
      };
    };
}
