{
  users.users.hydra-mirror =
    { description = "Channel mirroring user";
      home = "/home/hydra-mirror";
      isNormalUser = true;
      openssh.authorizedKeys.keys = with import ../ssh-keys.nix; [ eelco rob ];
      uid = 497;
    };
}
