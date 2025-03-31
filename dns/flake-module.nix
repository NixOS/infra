{
  perSystem =
    { pkgs, ... }:
    {
      devShells.dnscontrol = pkgs.mkShellNoCC {
        packages = [
          pkgs.dnscontrol
        ];
      };
      checks.dnscontrol = pkgs.runCommand "dnscontrol" { } ''
        cd ${./.}
        ${pkgs.dnscontrol}/bin/dnscontrol check
        touch $out
      '';
    };
}
