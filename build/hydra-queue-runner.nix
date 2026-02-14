{
  config,
  inputs,
  lib,
  ...
}:

let
  machines = [
    "elated-minsky"
    "goofy-hopcroft"
    "hopeful-rivest"
    "sleepy-brown"
    "eager-heisenberg"
    "enormous-catfish"
    "growing-jennet"
    "intense-heron"
    "kind-lumiere"
    "maximum-snail"
    "sweeping-filly"
  ];
in
{
  imports = [
    inputs.hydra-queue-runner.nixosModules.queue-runner
  ];

  age.secrets = lib.listToAttrs (
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

      extraConfig = ''
        access_log /var/log/nginx/queue-runner.log;
      '';

      locations."/".extraConfig = ''
        # This is necessary so that grpc connections do not get closed early
        # see https://stackoverflow.com/a/67805465
        client_body_timeout 31536000s;
        client_max_body_size 0;

        grpc_pass grpc://${config.services.queue-runner-dev.grpc.address}:${toString config.services.queue-runner-dev.grpc.port};

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

  services.queue-runner-dev = {
    enable = true;
    settings = {
      dbUrl = "postgres://hydra@10.0.40.3:5432/hydra";
      machineFreeFn = "DynamicWithMaxJobLimit";
      stepSortFn = "WithRdeps";
      # dispatchTriggerTimerInS?
      queueTriggerTimerInS = 60;
      concurrentUploadLimit = 48;
      maxConcurrentDownloads = 48;
      remoteStoreAddr = [
        "s3://nix-cache?secret-key=/var/lib/hydra/queue-runner/keys/cache.nixos.org-1/secret&write-nar-listing=1&compression=zstd&compression-level=19&ls-compression=zstd&log-compression=zstd&index-debug-info=true"
      ];
      rootsDir = "/nix/var/nix/gcroots/hydra";
      tokenListPath = map (machine: config.age.secrets."${machine}-queue-runner-token".path) machines;
    };
  };
}
