let
  keys = import ../ssh-keys.nix;

  secrets = with keys; {
    alertmanager-matrix-forwarder = [ machines.eris ];
    fastly-read-only-api-token = [ machines.eris ];
    hydra-mirror-aws-credentials = [ machines.pluto ];
    hydra-mirror-git-credentials = [ machines.pluto ];
    packet-sd-env = [ machines.eris ];
    prometheus-packet-spot-market-price-exporter = [ machines.eris ];
    rfc39-credentials = [ machines.eris ];
    rfc39-github = [ machines.eris ];
    rfc39-record-push = [ machines.eris ];
    tarball-mirror-aws-credentials = [ machines.pluto ];
  };
in
  builtins.listToAttrs (
    map (secretName: {
      name = "secrets/${secretName}.age";
      value.publicKeys = secrets."${secretName}" ++ keys.infra-core;
    }) (builtins.attrNames secrets)
  )
