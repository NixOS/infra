{
  rustPackages,
  fetchFromGitHub,
  pkg-config,
  openssl,
  zlib,
  protobuf,
  lib,
  makeWrapper,
  nix,
}:
let
  version = "unstable-2025-07-31";
  src = fetchFromGitHub {
    owner = "helsinki-systems";
    repo = "hydra-queue-runner";
    rev = "71f5293fcf152b16f21b1fca3c65d3b140da8f8e";
    hash = "sha256-N15GfzMyuCoL6D5sJEFJs6dgGX0NtMhB45SmY0muRVc=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-FEY2f7y41GctE/esFTmZc4Tl+rquCByM3ine80isC9w=";
  nativeBuildInputs = [
    pkg-config
    protobuf
    makeWrapper
  ];
  buildInputs = [
    openssl
    zlib
    protobuf
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
      wrapProgram $out/bin/queue-runner --prefix PATH : ${lib.makeBinPath [ nix ]}
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
      wrapProgram $out/bin/builder --prefix PATH : ${lib.makeBinPath [ nix ]}
    '';

    meta = meta // {
      mainProgram = "builder";
    };
  });
}
