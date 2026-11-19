let
  keys = import ../keys.nix;

  secrets = with keys.ssh.machines; {
    alertmanager-matrix-forwarder = [ titan ];
    alertmanager-oauth2-proxy-env = [ titan ];
    elasticsearch-exporter-env = [ titan ];
    fastly-exporter-env = [ titan ];
    grafana-secret-key = [ titan ];
    hydra-aws-credentials = [ mimas ];
    hydra-github-client-secret = [ mimas ];
    hydra-mirror-aws-credentials = [ titan ];
    hydra-mirror-git-credentials = [ titan ];
    owncast-admin-password = [ titan ];
    rfc39-credentials = [ titan ];
    rfc39-github = [ titan ];
    rfc39-record-push = [ titan ];
    storagebox-exporter-token = [ titan ];
    tarball-mirror-aws-credentials = [ titan ];
    titan-backup-secret = [ titan ];
    titan-backup-ssh-key = [ titan ];
    zrepl-ssh-key = [ mimas ];

    # builders/
    elated-minsky-queue-runner-token = [
      mimas
      elated-minsky
    ];
    goofy-hopcroft-queue-runner-token = [
      mimas
      goofy-hopcroft
    ];
    hopeful-rivest-queue-runner-token = [
      mimas
      hopeful-rivest
    ];
    sleepy-brown-queue-runner-token = [
      mimas
      sleepy-brown
    ];

    # macs/
    eager-heisenberg-queue-runner-token = [
      mimas
      eager-heisenberg
    ];
    enormous-catfish-queue-runner-token = [
      mimas
      enormous-catfish
    ];
    growing-jennet-queue-runner-token = [
      mimas
      growing-jennet
    ];
    intense-heron-queue-runner-token = [
      mimas
      intense-heron
    ];
    kind-lumiere-queue-runner-token = [
      mimas
      kind-lumiere
    ];
    maximum-snail-queue-runner-token = [
      mimas
      maximum-snail
    ];
    norwegian-blue-queue-runner-token = [
      mimas
      norwegian-blue
    ];
    sweeping-filly-queue-runner-token = [
      mimas
      sweeping-filly
    ];
  };

  # Not all SSH key types support encryption
  filterUnsupportedKeys =
    keys:
    builtins.filter (
      key:
      let
        # tokenize ssh key
        parts = builtins.split "[[:space:]]+" key;

        # first token is the key type
        keyType = builtins.elemAt parts 0;
      in
      # filter out unsupported key types
      !(builtins.elem keyType [
        # sk-* keys cannot do encryption or key derivation
        # https://github.com/FiloSottile/age/issues/537#issuecomment-1907361675
        # https://github.com/str4d/rage/issues/272#issuecomment-970193691
        "sk-ssh-ed25519@openssh.com"
        # "not worth implementing"
        # https://github.com/FiloSottile/age/issues/142#issuecomment-1001161195
        "ecdsa-sha2-nistp256"
      ])
    ) keys;

in
builtins.listToAttrs (
  map (secretName: {
    name = "secrets/${secretName}.age";
    value.publicKeys = secrets."${secretName}" ++ (filterUnsupportedKeys keys.age.groups.infra-core);
  }) (builtins.attrNames secrets)
)
