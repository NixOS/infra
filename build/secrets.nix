let
  keys = import ../ssh-keys.nix;

  secrets = with keys; {
    alertmanager-matrix-forwarder = [ machines.pluto ];
    alertmanager-oauth2-proxy-env = [ machines.pluto ];
    fastly-exporter-env = [ machines.pluto ];
    hydra-aws-credentials = [ machines.mimas ];
    hydra-github-client-secret = [ machines.mimas ];
    hydra-mirror-aws-credentials = [ machines.pluto ];
    hydra-mirror-git-credentials = [ machines.pluto ];
    owncast-admin-password = [ machines.pluto ];
    pluto-backup-secret = [ machines.pluto ];
    pluto-backup-ssh-key = [ machines.pluto ];
    rfc39-credentials = [ machines.pluto ];
    rfc39-github = [ machines.pluto ];
    rfc39-record-push = [ machines.pluto ];
    tarball-mirror-aws-credentials = [ machines.pluto ];
    zrepl-ssh-key = [ machines.titan ];
  };
in
builtins.listToAttrs (
  map (secretName: {
    name = "secrets/${secretName}.age";
    value.publicKeys = secrets."${secretName}" ++ keys.infra-core;
  }) (builtins.attrNames secrets)
)
