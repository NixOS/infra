{
  config,
  inputs,
  lib,
  ...
}:

{
  imports = [
    inputs.agenix.darwinModules.age
    inputs.hydra.darwinModules.builder
  ];

  age.secrets."queue-runner-token" = {
    file = ../../build/secrets/${config.networking.localHostName}-queue-runner-token.age;
    owner = "hydra-queue-builder";
  };

  services.hydra-queue-builder-dev = {
    enable = true;
    queueRunnerAddr = "https://queue-runner.hydra.nixos.org";
    authorizationFile = config.age.secrets."queue-runner-token".path;
    maxJobs = if lib.elem "big-parallel" (config.nix.settings.system-features or [ ]) then 2 else 4;
    # Required for presigned uploads: builders fetch dependencies via
    # substitution and upload results to s3 directly.
    useSubstitutes = true;
  };
}
