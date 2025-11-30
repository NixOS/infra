{
  rustPackages_1_91,
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
  withOtel ? false,
}:
let
  version = "unstable-2025-11-30";
  src = fetchFromGitHub {
    owner = "helsinki-systems";
    repo = "hydra-queue-runner";
    rev = "66d8c5d094987f6f54ec81b488812b999358267b";
    hash = "sha256-MwmnMExE2xDtZZFUXVec1xThvGx2GJUdFEVVOMtlF3Q=";
  };
  cargoHash = "sha256-jfM+1fa0LhIP0aB+sbEsRY1ps2cM2PLqlno/W+Lc1lQ=";
  nativeBuildInputs = [
    pkg-config
    protobuf
    makeWrapper
  ];
  buildInputs = [
    openssl
    zlib
    protobuf

    nixVersions.nix_2_32
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
  runner = rustPackages_1_91.rustPlatform.buildRustPackage {
    pname = "hydra-queue-runner";
    inherit version src;
    __structuredAttrs = true;
    strictDeps = true;

    inherit
      cargoHash
      nativeBuildInputs
      buildInputs
      ;

    buildAndTestSubdir = "queue-runner";
    buildFeatures = lib.optional withOtel "otel";
    doCheck = false;

    postInstall = ''
      wrapProgram $out/bin/queue-runner \
        --prefix PATH : ${lib.makeBinPath [ nixVersions.nix_2_32 ]} \
        --set-default JEMALLOC_SYS_WITH_MALLOC_CONF "background_thread:true,narenas:1,tcache:false,dirty_decay_ms:0,muzzy_decay_ms:0,abort_conf:true"
    '';

    meta = meta // {
      mainProgram = "queue-runner";
    };
  };

  builder = rustPackages_1_91.rustPlatform.buildRustPackage {
    pname = "hydra-queue-builder";
    inherit src version;
    __structuredAttrs = true;
    strictDeps = true;

    inherit
      cargoHash
      nativeBuildInputs
      buildInputs
      ;

    buildAndTestSubdir = "builder";
    buildFeatures = lib.optional withOtel "otel";
    doCheck = false;

    postInstall = ''
      wrapProgram $out/bin/builder \
        --prefix PATH : ${lib.makeBinPath [ nixVersions.nix_2_32 ]} \
        --set-default JEMALLOC_SYS_WITH_MALLOC_CONF "background_thread:true,narenas:1,tcache:false,dirty_decay_ms:0,muzzy_decay_ms:0,abort_conf:true"
    '';

    meta = meta // {
      mainProgram = "builder";
    };
  };
}
