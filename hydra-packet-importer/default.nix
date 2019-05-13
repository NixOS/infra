{ python3 }:
python3.pkgs.buildPythonApplication {
  name = "hydra-packet-importer";
  src = ./.;

  format = "other";

  propagatedBuildInputs = [
    python3.pkgs.packet-python
  ];

  installPhase = ''
    mkdir -p $out/bin
    mv import.py $out/bin/hydra-packet-importer
  '';
}
