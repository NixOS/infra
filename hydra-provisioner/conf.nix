{

  tag = "hydra-provisioned-nixos-org";

  systemTypes.x86_64-linux = {
    nixopsExpr = builtins.toPath ./nixops.nix;
    nixPath = [ "nixpkgs=channel:nixos-17.09" ];
    minMachines = 0;
    maxMachines = 12;
    ignoredRunnables = 250;
    runnablesPerMachine = 50;
    maxJobs = 4;
    sshKey = "/var/lib/hydra/queue-runner/.ssh/id_buildfarm_rsa";
  };

}
