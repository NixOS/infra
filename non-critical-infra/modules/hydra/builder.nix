{ inputs, config, ... }:
let
  nodes = {
    ofborg-eval02 = "eval02.ofborg.org";
    ofborg-eval03 = "eval03.ofborg.org";
    ofborg-eval04 = "eval04.ofborg.org";
    ofborg-build01 = "build01.ofborg.org";
    ofborg-build02 = "build02.ofborg.org";
    ofborg-build03 = "build03.ofborg.org";
    ofborg-build04 = "build04.ofborg.org";
    ofborg-build05 = "build05.ofborg.org";
  };
  nodePath = nodes."${config.networking.hostName}";
in
{
  imports = [
    inputs.hydra-staging.nixosModules.builder
  ];

  services.hydra-queue-builder-dev = {
    enable = true;
    queueRunnerAddr = "https://queue-runner.staging-hydra.nixos.org";
    maxJobs = 2;
    mtls = {
      serverRootCaCertPath = ../../hosts/staging-hydra/ca.crt;
      clientCertPath = "${../../hosts/${nodePath}/client.crt}";
      clientKeyPath = config.sops.secrets."queue-runner-client.key".path;
      domainName = "queue-runner.staging-hydra.nixos.org";
    };
  };

  sops.secrets."queue-runner-client.key" = {
    owner = "hydra-queue-builder";
    restartUnits = [ "hydra-queue-builder-dev.service" ];
    sopsFile = ../../secrets/ofborg.${nodePath}.yml;
  };
}
