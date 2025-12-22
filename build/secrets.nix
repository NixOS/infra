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
    storagebox-exporter-token = [ machines.pluto ];
    tarball-mirror-aws-credentials = [ machines.pluto ];
    zrepl-ssh-key = [ machines.titan ];

    # builders/
    elated-minsky-queue-runner-token = with machines; [
      mimas
      elated-minsky
    ];
    goofy-hopcroft-queue-runner-token = with machines; [
      mimas
      goofy-hopcroft
    ];
    hopeful-rivest-queue-runner-token = with machines; [
      mimas
      hopeful-rivest
    ];
    sleepy-brown-queue-runner-token = with machines; [
      mimas
      sleepy-brown
    ];
  };
in
builtins.listToAttrs (
  map (secretName: {
    name = "secrets/${secretName}.age";
    value.publicKeys = secrets."${secretName}" ++ keys.infra-core;
  }) (builtins.attrNames secrets)
)
