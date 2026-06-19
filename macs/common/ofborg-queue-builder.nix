{
  config,
  inputs,
  lib,
  ...
}:

{
  imports = [
    inputs.hydra.darwinModules.builder
  ];

  services.hydra-queue-builder-dev = {
    enable = true;
    queueRunnerAddr = "https://queue-runner.staging-hydra.nixos.org";
    maxJobs = 2;
    mtls = {
      serverRootCaCertPath = builtins.path {
        path = ../../non-critical-infra/hosts/staging-hydra/ca.crt;
        name = "staging-hydra-ca.crt";
      };
      clientCertPath = builtins.path {
        path = ../ofborg-ca/client-${config.networking.hostName}.crt;
        name = "client-${config.networking.hostName}.crt";
      };
      clientKeyPath = config.sops.secrets."queue-runner-client.key".path;
      domainName = "queue-runner.staging-hydra.nixos.org";
    };
  };

  sops.secrets."queue-runner-client.key" = {
    owner = "hydra-queue-builder";
    sopsFile = ../secrets/${config.networking.hostName}.yml;
  };

  users.users.hydra-queue-builder.home = lib.mkForce "/private/var/lib/hydra-queue-builder";
}
