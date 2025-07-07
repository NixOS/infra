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
  version = "unstable-2025-08-07";
  src = fetchFromGitHub {
    owner = "helsinki-systems";
    repo = "hydra-queue-runner";
    rev = "54b3c9351d2ae10be5c4d1b97cc0f86300cd70ca";
    hash = "sha256-gR2DzWkTykM9GdW3Nf/V8eRv68fl3aO+NW0zNPFSRT0=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-oNUMmFfts4rjBX0k5mzsxpYA2JqgsRu1nMRFf/2rZa8=";
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
