{
  rustPackages_1_88,
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
  version = "unstable-2025-11-05";
  src = fetchFromGitHub {
    owner = "helsinki-systems";
    repo = "hydra-queue-runner";
    rev = "81e6209e9107a62e9fba3d29f2ead8e9cf35bea1";
    hash = "sha256-MGoC9bLa9Ih66UbHkxGuAGvj/GfPZzG9N6liiHX0Sos=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-eFfrwLUnI35WhzO+enr2dTe5blwY00cGQoT5mfs9ZTw=";
  nativeBuildInputs = [
    pkg-config
    protobuf
    makeWrapper
  ];
  buildInputs = [
    openssl
    zlib
    protobuf

    nixVersions.nix_2_31
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
  runner = rustPackages_1_88.rustPlatform.buildRustPackage {
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

    buildAndTestSubdir = "queue-runner";
    buildFeatures = lib.optional withOtel "otel";

    postInstall = ''
      wrapProgram $out/bin/queue-runner \
        --prefix PATH : ${lib.makeBinPath [ nixVersions.nix_2_31 ]} \
        --set-default JEMALLOC_SYS_WITH_MALLOC_CONF "background_thread:true,narenas:1,tcache:false,dirty_decay_ms:0,muzzy_decay_ms:0,abort_conf:true"
    '';

    meta = meta // {
      mainProgram = "queue-runner";
    };
  };

  builder = rustPackages_1_88.rustPlatform.buildRustPackage {
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

    buildAndTestSubdir = "builder";
    buildFeatures = lib.optional withOtel "otel";

    postInstall = ''
      wrapProgram $out/bin/builder \
        --prefix PATH : ${lib.makeBinPath [ nixVersions.nix_2_31 ]} \
        --set-default JEMALLOC_SYS_WITH_MALLOC_CONF "background_thread:true,narenas:1,tcache:false,dirty_decay_ms:0,muzzy_decay_ms:0,abort_conf:true"
    '';

    meta = meta // {
      mainProgram = "builder";
    };
  };
}
