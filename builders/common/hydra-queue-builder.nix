{
  config,
  inputs,
  ...
}:

{
  imports = [
    inputs.hydra.nixosModules.builder
  ];

  age.secrets."queue-runner-token" = {
    file = ../../build/secrets/${config.networking.hostName}-queue-runner-token.age;
    owner = "hydra-queue-builder";
  };

  services.hydra-queue-builder-dev = {
    enable = true;
    queueRunnerAddr = "https://queue-runner.hydra.nixos.org";
    authorizationFile = config.age.secrets."queue-runner-token".path;
    maxJobs = config.nix.settings.max-jobs;
    # Required for presigned uploads: builders fetch dependencies via
    # substitution and upload results to s3 directly.
    useSubstitutes = true;
    # Align this with what our GC settings
    storeAvailThreshold = 5.0;
    # Tolerate only minimal contention before we stop scheduling new jobs
    cpuPsiThreshold = 15.0;
  };
}
