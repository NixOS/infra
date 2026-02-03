{
  config,
  inputs,
  ...
}:

{
  imports = [
    inputs.hydra-queue-runner.nixosModules.queue-builder
  ];

  age.secrets."queue-runner-token" = {
    file = ../../build/secrets/${config.networking.hostName}-queue-runner-token.age;
    owner = "hydra-queue-builder";
  };

  services.queue-builder-dev = {
    enable = true;
    queueRunnerAddr = "https://queue-runner.hydra.nixos.org";
    authorizationFile = config.age.secrets."queue-runner-token".path;
  };
}
