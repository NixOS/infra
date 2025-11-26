{
  pkgs,
  ...
}:

let

  diffoscopeWrapper = pkgs.writeScript "diffoscope-wrapper" ''
    #! ${pkgs.stdenv.shell}
    exec >&2
    echo ""
    echo "non-determinism detected in $2; diff with previous round follows:"
    echo ""
    time ${pkgs.util-linux}/bin/runuser -u diffoscope -- ${pkgs.diffoscope}/bin/diffoscope "$1" "$2"
    exit 0
  '';

in

{

  nix.extraOptions = ''
    diff-hook = ${diffoscopeWrapper}
  '';

  # Don't run diffoscope as root.
  users.extraUsers.diffoscope = {
    description = "Diffoscope containment user";
    group = "diffoscope";
    isSystemUser = true;
  };
  users.groups.diffoscope = { };

}
