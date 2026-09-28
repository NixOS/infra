{ pkgs, ... }:

pkgs.runCommand "nixpkgs-update-supervisor-test"
  {
    buildInputs = [ (pkgs.python3.withPackages (ps: [ ps.asyncinotify ])) ];
    files = pkgs.lib.fileset.toSource {
      root = ./.;
      fileset = pkgs.lib.fileset.unions [
        ./supervisor.py
        ./supervisor_test.py
      ];
    };
  }
  ''
    python3 $files/supervisor_test.py
    touch $out
  ''
