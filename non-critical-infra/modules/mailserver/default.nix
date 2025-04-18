{ config, pkgs, ... }:

{
  imports = [
    ./mailing-lists.nix
    ./postsrsd.nix
  ];

  mailserver = {
    enable = true;
    certificateScheme = "acme-nginx";

    fqdn = config.networking.fqdn;

    domains = [ "nixos.org" ];

    dmarcReporting = {
      enable = true;
      domain = "nixos.org";
      fromName = "NixOS.org DMARC Report";
      organizationName = "NixOS";
    };
  };

  sops.secrets."nixos.org.mail.key" = {
    format = "binary";
    owner = "opendkim";
    group = "opendkim";
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
}
