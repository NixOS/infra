{ config, ... }:

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
}
