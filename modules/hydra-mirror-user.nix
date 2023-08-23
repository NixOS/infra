{
  users.users.hydra-mirror =
    { description = "Channel mirroring user";
      home = "/home/hydra-mirror";
      openssh.authorizedKeys.keys = (import ../ssh-keys.nix).infra-core;
      uid = 497;
      group = "hydra-mirror";
    };

  users.groups.hydra-mirror = {};
}
