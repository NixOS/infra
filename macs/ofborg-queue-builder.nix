{
  config,
  inputs,
  ...
}:

{
  imports = [
    inputs.hydra-staging.darwinModules.builder
  ];

  services.hydra-queue-builder-dev = {
    enable = true;
    queueRunnerAddr = "https://queue-runner.staging-hydra.nixos.org";
    maxJobs = 2;
    mtls = {
      serverRootCaCertPath = ../non-critical-infra/hosts/staging-hydra/ca.crt;
      clientCertPath = "${./ofborg-ca/client-${config.networking.hostName}.crt}";
      clientKeyPath = config.sops.secrets."queue-runner-client.key".path;
      domainName = "queue-runner.staging-hydra.nixos.org";
    };
  };

  sops.secrets."queue-runner-client.key" = {
    owner = "hydra-queue-builder";
    sopsFile = ./secrets/${config.networking.hostName}.yml;
  };
}
