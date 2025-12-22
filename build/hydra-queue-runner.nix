{
  config,
  lib,
  ...
}:

let
  machines = [
    "eager-heisenberg"
    "elated-minsky"
    "enormous-catfish"
    "goofy-hopcroft"
    "growing-jennet"
    "hopeful-rivest"
    "intense-heron"
    "kind-lumiere"
    "maximum-snail"
    "norwegian-blue"
    "sleepy-brown"
    "sweeping-filly"
  ];
in
{
  age.secrets = {
    hydra-aws-credentials = {
      file = ./secrets/hydra-aws-credentials.age;
      path = "/var/lib/hydra/queue-runner/.aws/credentials";
      owner = "hydra-queue-runner";
      group = "hydra";
    };
  }
  // lib.listToAttrs (
    map (
      machine:
      lib.nameValuePair "${machine}-queue-runner-token" {
        file = ./secrets/${machine}-queue-runner-token.age;
      }
    ) machines
  );

  services.nginx = {
    enable = true;
    virtualHosts."queue-runner.hydra.nixos.org" = {
      enableACME = true;
      forceSSL = true;

      locations."/".extraConfig = ''
        # This is necessary so that grpc connections do not get closed early
        # see https://stackoverflow.com/a/67805465
        client_body_timeout 31536000s;
        client_max_body_size 0;

        grpc_pass grpc://${config.services.hydra-queue-runner-dev.grpc.address}:${toString config.services.hydra-queue-runner-dev.grpc.port};

        grpc_read_timeout 31536000s; # 1 year in seconds
        grpc_send_timeout 31536000s; # 1 year in seconds
        grpc_socket_keepalive on;

        grpc_set_header Host $host;
        grpc_set_header X-Real-IP $remote_addr;
        grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        grpc_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };

  services.hydra-queue-runner-dev = {
    enable = true;
    awsCredentialsFile = config.age.secrets."hydra-aws-credentials".path;
    settings = {
      dbUrl = "postgres://hydra@10.0.40.3:5432/hydra";
      machineFreeFn = "DynamicWithMaxJobLimit";
      stepSortFn = "WithRdeps";
      # TODO: Expose dispatchTriggerTimerInS, defaults to 120s
      queueTriggerTimerInS = 60;
      concurrentUploadLimit = 48;
      maxConcurrentDownloads = 48;
      remoteStoreAddr = [
        "s3://nix-cache?${
          lib.concatStringsSep "&" [
            "secret-key=/var/lib/hydra/queue-runner/keys/cache.nixos.org-1/secret"
            "write-nar-listing=1"
            "compression=zstd"
            "compression-level=19"
            "ls-compression=zstd"
            "log-compression=zstd"
            "index-debug-info=true"
          ]
        }"
      ];
      rootsDir = "/nix/var/nix/gcroots/hydra";
      tokenPaths = map (machine: config.age.secrets."${machine}-queue-runner-token".path) machines;
    };
  };
}
