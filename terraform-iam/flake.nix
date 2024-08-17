{
  inputs.nixpkgs.url = "nixpkgs/master";

  outputs =
    { nixpkgs }:
    {

      devShell.x86_64-linux =
        with import nixpkgs { system = "x86_64-linux"; };
        mkShell {
          packages = [
            awscli2
            (terraform.withPlugins (
              p: with p; [
                aws
                fastly
                netlify
                secret
              ]
            ))
          ];

          shellHook = ''
            alias tf=terraform
          '';
        };

    };

}
