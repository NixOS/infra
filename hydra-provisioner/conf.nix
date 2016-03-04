{

  tag = "hydra-provisioned-nixos-org";

  statusCommand = [ "ssh" "-x" "hydra-queue-runner@lucifer.ewi.tudelft.nl" "PGPASSFILE=/var/lib/hydra/pgpass-queue-runner" "hydra-queue-runner" "--status" ];
  updateCommand = [ "ssh" "-x" "hydra-queue-runner@lucifer.ewi.tudelft.nl" "cat > /var/lib/hydra/provisioner/machines" ];

  systemTypes.x86_64-linux = {
    nixopsExpr = builtins.toPath ./nixops.nix;
    nixPath = [ "nixpkgs=https://nixos.org/channels/nixos-15.09-small/nixexprs.tar.xz" ];
    maxMachines = 12;
    ignoredRunnables = 250;
    runnablesPerMachine = 50;
    maxJobs = 4;
    sshKey = "/var/lib/hydra/queue-runner/.ssh/id_buildfarm";
  };

}
