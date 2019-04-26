{ stdenv, python3 }:
stdenv.mkDerivation {
  name = "hydra-packet-importer";
  src = ./.;

  buildInputs = [
    (python3.withPackages (ps: [
      ps.packet-python
    ]))
  ];

  buildPhase = ''
    patchShebangs ./import.py
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv ./import.py $out/bin/hydra-packet-importer
  '';
}
