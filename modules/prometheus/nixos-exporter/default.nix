{ python3Packages }:

with python3Packages;

buildPythonApplication {
  pname = "prometheus-nixos-exporter";
  version = "0.0";
  pyproject = true;

  src = ./.;

  nativeBuildInputs = [
    setuptools
  ];

  propagatedBuildInputs = [
    packaging
    prometheus-client
  ];
}
