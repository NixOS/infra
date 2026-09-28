let
  keys = import ../../keys.nix;
in

{
  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = with keys.ssh; groups.infra-core;
}
