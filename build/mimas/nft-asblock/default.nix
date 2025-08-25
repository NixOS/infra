{ python3Packages }:

with python3Packages;

buildPythonApplication {
  pname = "nft-asblock";
  version = "0.0";
  format = "pyproject";

  src = ./.;

  build-system = [ uv-build ];

  dependencies = [
    httpx
    typer
  ];

  meta.mainProgram = "nft-asblock";
}
