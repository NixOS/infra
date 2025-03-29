{
  perSystem =
    { pkgs, ... }:
    {
      devShells.dnscontrol = pkgs.mkShellNoCC {
        packages = [
          pkgs.dnscontrol
        ];
      };
    };
}
