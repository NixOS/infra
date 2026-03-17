{
  config,
  inputs,
  lib,
  ...
}:

{
  imports = [
    inputs.hydra-staging.nixosModules.linux-builder
  ];

  config = lib.mkIf false {
    age.secrets."queue-runner-token" = {
      file = ../../build/secrets/${config.networking.hostName}-queue-runner-token.age;
      owner = "hydra-queue-builder";
    };

    services.hydra-queue-builder-dev = {
      enable = true;
      queueRunnerAddr = "https://queue-runner.hydra.nixos.org";
      authorizationFile = config.age.secrets."queue-runner-token".path;
    };
  };
}
