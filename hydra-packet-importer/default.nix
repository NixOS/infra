{ python3 }:
python3.pkgs.buildPythonApplication {
  name = "hydra-packet-importer";
  src = ./.;

  format = "other";

  nativeBuildInputs = [ python3.pkgs.mypy ];

  propagatedBuildInputs = [ python3.pkgs.packet-python ];

  installPhase = ''
    mypy --ignore-missing-imports ./import.py
    mkdir -p $out/bin
    mv import.py $out/bin/hydra-packet-importer
  '';
}
