let
  pkgs =
    import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable-small.tar.gz")
      {
        config.allowAliases = false;
        config.allowUnfree = true;
      };
in
# code in the following let block was copied under the MIT License from
# https://github.com/NixOS/nixpkgs/blob/5422d9b1f44033691eb17149a463de693d68de52/maintainers/scripts/update.nix
let
  inherit (pkgs) lib;

  # Remove duplicate elements from the list based on some extracted value. O(n^2) complexity.
  nubOn =
    f: list:
    if list == [ ] then
      [ ]
    else
      let
        x = lib.head list;
        xs = lib.filter (p: f x != f p) (lib.drop 1 list);
      in
      [ x ] ++ nubOn f xs;

  /*
    Recursively find all packages (derivations) in `pkgs` matching `cond` predicate.

    Type: packagesWithPath :: AttrPath → (AttrPath → derivation → bool) → AttrSet → List<AttrSet{attrPath :: str; package :: derivation; }>
          AttrPath :: [str]

    The packages will be returned as a list of named pairs comprising of:
      - attrPath: stringified attribute path (based on `rootPath`)
      - package: corresponding derivation
  */
  packagesWithPath =
    rootPath: cond: pkgs:
    let
      packagesWithPathInner =
        path: pathContent:
        let
          result = builtins.tryEval pathContent;

          somewhatUniqueRepresentant =
            { package, ... }:
            {
              inherit (package) updateScript;
              # Some updaters use the same `updateScript` value for all packages.
              # Also compare `meta.description`.
              position = package.meta.position or null;
              # We cannot always use `meta.position` since it might not be available
              # or it might be shared among multiple packages.
            };

          dedupResults = lst: nubOn somewhatUniqueRepresentant (lib.concatLists lst);
        in
        if result.success then
          let
            evaluatedPathContent = result.value;
          in
          if lib.isDerivation evaluatedPathContent then
            lib.optional (cond path evaluatedPathContent) {
              attrPath = lib.concatStringsSep "." path;
              package = evaluatedPathContent;
            }
          else if lib.isAttrs evaluatedPathContent then
            # If user explicitly points to an attrSet or it is marked for recursion, we recur.
            if
              path == rootPath
              || evaluatedPathContent.recurseForDerivations or false
              || evaluatedPathContent.recurseForRelease or false
            then
              dedupResults (
                lib.mapAttrsToList (name: elem: packagesWithPathInner (path ++ [ name ]) elem) evaluatedPathContent
              )
            else
              [ ]
          else
            [ ]
        else
          [ ];
    in
    packagesWithPathInner rootPath pkgs;

  # Recursively find all packages (derivations) in `pkgs` matching `cond` predicate.
  packagesWith = packagesWithPath [ ];

  # Recursively find all packages in `pkgs` with updateScript matching given predicate.
  packagesWithUpdateScriptMatchingPredicate =
    cond: packagesWith (path: pkg: builtins.hasAttr "updateScript" pkg && cond path pkg);

in

let

  allPackagesWithUpdateScript = packagesWithUpdateScriptMatchingPredicate (_path: _package: true) (
    # exclude lix/nix overrides before deduplication
    builtins.removeAttrs pkgs [
      "lixPackageSets"
      "nixDependencies"
    ]
  );

in

lib.concatMapStrings (p: "${p.attrPath} 0 1\n") allPackagesWithUpdateScript
