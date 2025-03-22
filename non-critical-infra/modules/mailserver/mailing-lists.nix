{
  imports = [ ./mailing-lists-options.nix ];

  # If you wish to hide your email address, you can encrypt it with SOPS. Just
  # run `nix run .#encrypt-email address -- --help` and follow the instructions.
  #
  # If you wish to set up a login account for sending email, you must generate
  # an encrypted password. Run `nix run .#encrypt-email login -- --help` and
  # follow the instructions.
  mailing-lists = {
    # TODO: replace with the real `nixos.org` mailing lists.
    "test-list@nixos.org" = {
      forwardTo = [
        "jfly@playground.jflei.com"
        ../../secrets/jfly-email-address.umbriel
        "jeremyfleischman+subscriber@gmail.com"
      ];
    };
    "test-sender@nixos.org" = {
      forwardTo = [ "jeremy@playground.jflei.com" ];
      loginAccount.encryptedHashedPassword = ../../secrets/test-sender-email-login.umbriel;
    };
  };
}
