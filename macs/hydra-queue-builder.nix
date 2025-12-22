{
  config,
  inputs,
  lib,
  ...
}:

{
  imports = [
    inputs.agenix.darwinModules.age
    inputs.hydra-queue-runner.darwinModules.queue-builder
  ];

  age.secrets."queue-runner-token" = {
    file = ../build/secrets/${config.networking.localHostName}-queue-runner-token.age;
  };

  services.queue-builder-dev = {
    enable = true;
    queueRunnerAddr = "https://queue-runner.hydra.nixos.org";
    authorizationFile = config.age.secrets."queue-runner-token".path;
    maxJobs = if lib.elem "big-parallel" (config.nix.settings.system-features or [ ]) then 2 else 4;
  };
}
