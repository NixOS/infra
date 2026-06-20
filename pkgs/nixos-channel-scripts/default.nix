{
  lib,
  stdenv,
  pkg-config,
  nixVersions,
  nlohmann_json,
  boost,
  makeWrapper,
  perl,
  perlPackages,
  wget,
  git,
  nix,
  gnutar,
  xz,
  rsync,
  openssh,
  nix-index,
}:
let
  nixos-channel-native-programs = stdenv.mkDerivation {
    name = "nixos-channel-native-programs";

    strictDeps = true;

    nativeBuildInputs = [ pkg-config ];

    buildInputs = [
      nixVersions.nix_2_28
      nlohmann_json
      boost
    ];

    buildCommand = ''
      mkdir -p $out/bin

      $CXX \
        -Os -g -Wall \
        -std=c++14 \
        $(pkg-config --libs --cflags nix-store) \
        $(pkg-config --libs --cflags nix-main) \
        -I . \
        ${./index-debuginfo.cc} \
        -o $out/bin/index-debuginfo
    '';
  };
in
stdenv.mkDerivation {
  name = "nixos-channel-scripts";

  strictDeps = true;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = with perlPackages; [
    perl
    FileSlurp
    LWP
    LWPProtocolHttps
    ListMoreUtils
    DBDSQLite
    NetAmazonS3
  ];

  buildCommand = ''
    mkdir -p $out/bin

    cp ${./mirror-nixos-branch.pl} $out/bin/mirror-nixos-branch
    wrapProgram $out/bin/mirror-nixos-branch \
      --set PERL5LIB $PERL5LIB \
      --set XZ_OPT "-T0" \
      --prefix PATH : ${
        lib.makeBinPath [
          wget
          git
          nix
          gnutar
          xz
          rsync
          openssh
          nix-index
          nixos-channel-native-programs
        ]
      }

    patchShebangs $out/bin
  '';
}
