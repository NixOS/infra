{
  lib,
  mkpasswd,
  python3,
  sops,
}:

python3.pkgs.buildPythonApplication {
  name = "encrypt-email";
  src = ./.;

  format = "other";

  propagatedBuildInputs = [ python3.pkgs.click ];

  installPhase = ''
    mkdir -p $out/bin
    mv ./encrypt-email.py $out/bin/encrypt-email
    wrapProgram $out/bin/encrypt-email --prefix PATH : ${
      lib.makeBinPath [
        sops
        mkpasswd
      ]
    }
  '';
}
