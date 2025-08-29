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
  version = "unstable-2025-08-28";
  src = fetchFromGitHub {
    owner = "helsinki-systems";
    repo = "hydra-queue-runner";
    rev = "e3c3a21560c393cab397277e5ee90d84e84b4ee7";
    hash = "sha256-COdsCoU5IYLBvRRs68VHKZlPJBAJkY7MO0ok7naegfI=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-Ukm3Nbm+/CKNr64UtwMdVHWw386kQL+JaSFz3lnpc4Y=";
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
      wrapProgram $out/bin/queue-runner \
        --prefix PATH : ${lib.makeBinPath [ nixVersions.nix_2_29 ]} \
        --set-default JEMALLOC_SYS_WITH_MALLOC_CONF "background_thread:true,narenas:1,tcache:false,dirty_decay_ms:0,muzzy_decay_ms:0,abort_conf:true"
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
      wrapProgram $out/bin/builder \
        --prefix PATH : ${lib.makeBinPath [ nixVersions.nix_2_29 ]} \
        --set-default JEMALLOC_SYS_WITH_MALLOC_CONF "background_thread:true,narenas:1,tcache:false,dirty_decay_ms:0,muzzy_decay_ms:0,abort_conf:true"
    '';

    meta = meta // {
      mainProgram = "builder";
    };
  });
}
