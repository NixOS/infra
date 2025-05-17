{ config, ... }:
# We use `postsrsd` to enable Sender Rewriting Scheme (SRS) so mail we forward
# to another domain does not fail SPF. See
# https://github.com/NixOS/infra/issues/485#issuecomment-2787490679 for
# details.
{
  services.postsrsd = {
    enable = true;
    domains = [ "nixos.org" ];
    secretsFile = config.sops.secrets.postsrsd-secret.path;
  };

  # Configure postfix as per
  # https://github.com/roehling/postsrsd?tab=readme-ov-file#postfix-setup
  services.postfix.config = {
    sender_canonical_maps = "socketmap:unix:${config.services.postsrsd.socketPath}:forward";
    sender_canonical_classes = "envelope_sender";

    recipient_canonical_maps = "socketmap:unix:${config.services.postsrsd.socketPath}:reverse";
    recipient_canonical_classes = "envelope_recipient, header_recipient";
  };

  # ```
  # How to generate:
  #
  # ```console
  # cd non-critical-infra
  # SECRET_PATH=secrets/postsrsd-secret.umbriel
  # dd if=/dev/random bs=18 count=1 status=none | base64 > "$SECRET_PATH"
  # sops encrypt --in-place "$SECRET_PATH"
  # ```
  sops.secrets.postsrsd-secret = {
    format = "binary";
    owner = config.services.postsrsd.user;
    group = config.services.postsrsd.group;
    sopsFile = ../../secrets/postsrsd-secret.umbriel;
    restartUnits = [ "postsrsd.service" ];
  };
}
