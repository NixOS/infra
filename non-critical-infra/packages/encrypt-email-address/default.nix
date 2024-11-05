{
  lib,
  python3,
  sops,
}:

python3.pkgs.buildPythonApplication {
  name = "encrypt-email-address";
  src = ./.;

  format = "other";

  propagatedBuildInputs = [ python3.pkgs.click ];

  installPhase = ''
    mkdir -p $out/bin
    mv ./encrypt-email-address.py $out/bin/encrypt-email-address
    wrapProgram $out/bin/encrypt-email-address --prefix PATH : ${lib.makeBinPath [ sops ]}
  '';
}
