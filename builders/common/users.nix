let
  keys = import ../../keys.nix;
in

{
  users = {
    mutableUsers = false;
    users.root.openssh.authorizedKeys.keys = keys.ssh.groups.infra-core;
  };
}
