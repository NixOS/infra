{ config, pkgs, ... }:

{
  imports = [ ./mailing-lists.nix ];

  mailserver = {
    enable = true;
    certificateScheme = "acme-nginx";

    fqdn = config.networking.fqdn;

    # TODO: change to `nixos.org` when ready
    domains = [ "mail-test.nixos.org" ];
  };

  ### Mailing lists go here ###
  # If you wish to hide your email address, you can encrypt it with SOPS. Just
  # run `nix run .#encrypt-email address -- --help` and follow the instructions.
  #
  # If you wish to set up a login account for sending email, you must generate
  # an encrypted password. Run `nix run .#encrypt-email login -- --help` and
  # follow the instructions.
  mailing-lists = {
    # TODO: replace with the real `nixos.org` mailing lists.
    "test-list@mail-test.nixos.org" = {
      forwardTo = [
        "jfly@playground.jflei.com"
        ../../secrets/jfly-email-address.umbriel
        "jeremyfleischman+subscriber@gmail.com"
      ];
    };
    "test-sender@mail-test.nixos.org" = {
      forwardTo = [ "jeremy@playground.jflei.com" ];
      loginAccount.encryptedHashedPassword = ../../secrets/test-sender-email-login.umbriel;
    };
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
