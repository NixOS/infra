let
  keys = import ../keys.nix;

  secrets = with keys.ssh.machines; {
    alertmanager-matrix-forwarder = [ pluto ];
    alertmanager-oauth2-proxy-env = [ pluto ];
    fastly-exporter-env = [ pluto ];
    grafana-secret-key = [ pluto ];
    hydra-aws-credentials = [ mimas ];
    hydra-github-client-secret = [ mimas ];
    hydra-mirror-aws-credentials = [ pluto ];
    hydra-mirror-git-credentials = [ pluto ];
    owncast-admin-password = [ pluto ];
    pluto-backup-secret = [ pluto ];
    pluto-backup-ssh-key = [ pluto ];
    rfc39-credentials = [ pluto ];
    rfc39-github = [ pluto ];
    rfc39-record-push = [ pluto ];
    storagebox-exporter-token = [ pluto ];
    tarball-mirror-aws-credentials = [ pluto ];
    zrepl-ssh-key = [ titan ];

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
