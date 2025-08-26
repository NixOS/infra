{
  rustPackages,
  fetchFromGitHub,
  pkg-config,
  openssl,
  zlib,
  protobuf,
  lib,
  makeWrapper,
  nixVersions,
  nlohmann_json,
  libsodium,
  boost,
}:
let
  version = "unstable-2025-08-26";
  src = fetchFromGitHub {
    owner = "helsinki-systems";
    repo = "hydra-queue-runner";
    rev = "c7b947af0301a371baaf60e8dac74e547613b80a";
    hash = "sha256-OWQk5EGxPBcnc6+S2xhvrEUQXPhRcIYjCrbQf/EaP48=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-0pj08Gmo+UcWO8oBJFEDaUDpjwSZuJCTVVZtORgK5rM=";
  nativeBuildInputs = [
    pkg-config
    protobuf
    makeWrapper
  ];
  buildInputs = [
    openssl
    zlib
    protobuf

    nixVersions.nix_2_29
    nlohmann_json
    libsodium
    boost
  ];
  meta = {
    description = "Hydra Queue-Runner implemented in rust";
    homepage = "https://github.com/helsinki-systems/hydra-queue-runner";
    license = [ lib.licenses.gpl3 ];
    maintainers = [ lib.maintainers.conni2461 ];
    platforms = lib.platforms.all;
  };
in
{
  runner = rustPackages.rustPlatform.buildRustPackage (finalAttrs: {
    pname = "hydra-queue-runner";
    inherit version src;
    __structuredAttrs = true;
    strictDeps = true;

    inherit
      useFetchCargoVendor
      cargoHash
      nativeBuildInputs
      buildInputs
      ;

    cargoBuildFlags = [
      "-p"
      "queue-runner"
    ];
    cargoTestFlags = finalAttrs.cargoBuildFlags;

    postInstall = ''
      wrapProgram $out/bin/queue-runner --prefix PATH : ${lib.makeBinPath [ nixVersions.nix_2_29 ]}
    '';

    meta = meta // {
      mainProgram = "queue-runner";
    };
  });

  builder = rustPackages.rustPlatform.buildRustPackage (finalAttrs: {
    pname = "hydra-queue-builder";
    inherit src version;
    __structuredAttrs = true;
    strictDeps = true;

    inherit
      useFetchCargoVendor
      cargoHash
      nativeBuildInputs
      buildInputs
      ;

    cargoBuildFlags = [
      "-p"
      "builder"
    ];
    cargoTestFlags = finalAttrs.cargoBuildFlags;

    postInstall = ''
      wrapProgram $out/bin/builder --prefix PATH : ${lib.makeBinPath [ nixVersions.nix_2_29 ]}
    '';

    meta = meta // {
      mainProgram = "builder";
    };
  });
}
