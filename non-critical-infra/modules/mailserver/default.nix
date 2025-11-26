{
  inputs,
  config,
  pkgs,
  ...
}:

{
  imports = [
    inputs.simple-nixos-mailserver.nixosModule
    ./mailing-lists.nix
    ./freescout.nix
  ];

  # enabled through systemd.network.enable
  services.resolved.enable = false;

  mailserver = {
    enable = true;
    enableImap = false;
    stateVersion = 3;
    certificateScheme = "acme-nginx";

    fqdn = config.networking.fqdn;

    domains = [
      "nixcon.org"
      "nixos.org"
    ];

    srs.enable = true;
  };

  # https://nixos-mailserver.readthedocs.io/en/latest/backup-guide.html
  services.backup.includes = [ config.mailserver.mailDirectory ];

  sops.secrets."nixos.org.mail.key" = {
    format = "binary";
    owner = "rspamd";
    group = "rspamd";
    mode = "0600";

    # How to generate:
    #
    # ```console
    # cd non-critical-infra
    # DOMAIN=nixos.org
    # SELECTOR=mail
    # PRIVATE_KEY_PATH=secrets/$DOMAIN.$SELECTOR.key.umbriel
    # nix shell nixpkgs#opendkim --command opendkim-genkey --selector="$SELECTOR" --domain="$DOMAIN" --bits=1024
    # mv mail.private "$PRIVATE_KEY_PATH"
    # sops encrypt --in-place "$PRIVATE_KEY_PATH"
    # ```
    #
    # Next, look at `mail.txt` and update DNS accordingly.
    sopsFile = ../../secrets/nixos.org.mail.key.umbriel;

    # Ensure the file gets symlinked to where Simple NixOS Mailserver expects
    # to find it.
    path = "${config.mailserver.dkimKeyDirectory}/nixos.org.mail.key";
  };

  sops.secrets."nixcon.org.mail.key" = {
    format = "binary";
    owner = "rspamd";
    group = "rspamd";
    mode = "0600";
    sopsFile = ../../secrets/nixcon.org.mail.key.umbriel;
    path = "${config.mailserver.dkimKeyDirectory}/nixcon.org.mail.key";
  };

  services.postfix.config.bounce_template_file = "${pkgs.writeText "bounce-template.cf" ''
    failure_template = <<EOF
    Charset: us-ascii
    From: MAILER-DAEMON (Mail Delivery System)
    Subject: Undelivered Mail Returned to Sender
    Postmaster-Subject: Postmaster Copy: Undelivered Mail

    This is the mail system at host $myhostname.

    I'm sorry to have to inform you that your message could not
    be delivered to one or more recipients. It's attached below.

    For further assistance, please file an issue at
    https://github.com/NixOS/infra/issues/new. Please anonymize any personal
    email addresses in your report.

    If you do so, please include this problem report. You can
    delete your own text from the attached returned message.

                  The mail system
    EOF

    delay_template = <<EOF
    Charset: us-ascii
    From: MAILER-DAEMON (Mail Delivery System)
    Subject: Delayed Mail (still being retried)
    Postmaster-Subject: Postmaster Warning: Delayed Mail

    This is the mail system at host $myhostname.

    ####################################################################
    # THIS IS A WARNING ONLY.  YOU DO NOT NEED TO RESEND YOUR MESSAGE. #
    ####################################################################

    Your message could not be delivered for more than $delay_warning_time_hours hour(s).
    It will be retried until it is $maximal_queue_lifetime_days day(s) old.

    For further assistance, please file an issue at
    https://github.com/NixOS/infra/issues/new. Please anonymize any personal
    email addresses in your report.

    If you do so, please include this problem report. You can
    delete your own text from the attached returned message.

                       The mail system
    EOF
  ''}";

  services.postsrsd.secretsFile = config.sops.secrets.postsrsd-secret.path;

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
