{
  imports = [ ./mailing-lists-options.nix ];

  # If you wish to hide your email address, you can encrypt it with SOPS. Just
  # run `nix run .#encrypt-email address -- --help` and follow the instructions.
  #
  # If you wish to set up a login account for sending email, you must generate
  # an encrypted password. Run `nix run .#encrypt-email login -- --help` and
  # follow the instructions.
  mailing-lists = {
    # BEGIN TEST ADDRESSES
    # TODO: remove these testing email addresses after rollout is complete:
    #       https://github.com/NixOS/infra/issues/587
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
    # END TEST ADDRESS

    "community@nixos.org" = {
      forwardTo = [
        "moderation@nixos.org"
      ];
    };

    "finance@nixos.org" = {
      forwardTo = [
        ../../secrets/edolstra-email-address.umbriel # https://github.com/edolstra
        ../../secrets/kate-email-address.umbriel # https://discourse.nixos.org/u/kate
      ];
    };

    "foundation@nixos.org" = {
      forwardTo = [
        ../../secrets/edolstra-foundation-email-address.umbriel # https://github.com/edolstra
        ../../secrets/refroni-email-address.umbriel # https://github.com/refroni
        ../../secrets/kate-email-address.umbriel # https://discourse.nixos.org/u/kate
        ../../secrets/infinisil-email-address.umbriel # https://github.com/infinisil
        ../../secrets/ra33it0-email-address.umbriel # https://github.com/ra33it0
        ../../secrets/lassulus-email-address.umbriel # https://github.com/lassulus
        ../../secrets/ryantrinkle-email-address.umbriel # https://github.com/ryantrinkle
      ];
    };

    "fundraising@nixos.org" = {
      forwardTo = [
        ../../secrets/fricklerhandwerk-email-address.umbriel # https://github.com/fricklerhandwerk
      ];
    };

    "hostmaster@nixos.org" = {
      forwardTo = [
        "infra@nixos.org"
      ];
    };

    "infra@nixos.org" = {
      forwardTo = [
        ../../secrets/mweinelt-email-address.umbriel # https://github.com/mweinelt
        ../../secrets/zimbatm-email-address.umbriel # https://github.com/zimbatm
        ../../secrets/vcunat-email-address.umbriel # https://github.com/vcunat
        ../../secrets/edef1c-email-address.umbriel # https://github.com/edef1c
        ../../secrets/Mic92-email-address.umbriel # https://github.com/Mic92
      ];
    };

    "marketing@nixos.org" = {
      forwardTo = [
        ../../secrets/idabzo-email-address.umbriel # https://github.com/idabzo
        ../../secrets/therealpxc-email-address.umbriel # https://github.com/therealpxc
        ../../secrets/Kranzes-email-address.umbriel # https://github.com/Kranzes
        ../../secrets/tomberek-email-address.umbriel # https://github.com/tomberek
      ];
    };

    "moderation@nixos.org" = {
      forwardTo = [
        ../../secrets/lassulus-email-address.umbriel # https://github.com/lassulus
        ../../secrets/picnoir-email-address.umbriel # https://github.com/picnoir
        ../../secrets/uep-email-address.umbriel # https://discourse.nixos.org/u/uep
      ];
    };

    "ngi@nixos.org" = {
      forwardTo = [
        ../../secrets/fricklerhandwerk-email-address.umbriel # https://github.com/fricklerhandwerk
        ../../secrets/wamirez-email-address.umbriel # https://github.com/wamirez
        ../../secrets/idabzo-email-address.umbriel # https://github.com/idabzo
        ../../secrets/erictapen-email-address.umbriel # https://github.com/erictapen
        ../../secrets/eljamm-email-address.umbriel # https://github.com/eljamm
        ../../secrets/JulienMalka-email-address.umbriel # https://github.com/JulienMalka
        ../../secrets/OPNA2608-email-address.umbriel # https://github.com/OPNA2608
        ../../secrets/wegank-email-address.umbriel # https://github.com/wegank
        ../../secrets/erethon-email-address.umbriel # https://github.com/erethon
        ../../secrets/imincik-email-address.umbriel # https://github.com/imincik
      ];
      loginAccount.encryptedHashedPassword = ../../secrets/ngi-nixos-org-email-login.umbriel;
    };

    "nixcon@nixos.org" = {
      forwardTo = [
        ../../secrets/ners-email-address.umbriel # https://github.com/ners
        ../../secrets/john-rodewald-email-address.umbriel # https://github.com/john-rodewald
        ../../secrets/das-g-email-address.umbriel # https://github.com/das-g
        ../../secrets/refroni-nixcon-email-address.umbriel # https://github.com/refroni
        ../../secrets/ra33it0-email-address.umbriel # https://github.com/ra33it0
        ../../secrets/infinisil-nixcon-email-address.umbriel # https://github.com/infinisil
        ../../secrets/Nebucatnetzer-email-address.umbriel # https://github.com/Nebucatnetzer
        ../../secrets/andir-email-address.umbriel # https://github.com/andir
        ../../secrets/zmberber-email-address.umbriel # https://github.com/zmberber
        ../../secrets/a-kenji-email-address.umbriel # https://github.com/a-kenji
        ../../secrets/lassulus-nixcon-email-address.umbriel # https://github.com/lassulus
        ../../secrets/pinpox-email-address.umbriel # https://github.com/pinpox
        ../../secrets/ForsakenHarmony-email-address.umbriel # https://github.com/ForsakenHarmony
        ../../secrets/idabzo-email-address.umbriel # https://github.com/idabzo
        ../../secrets/picnoir-email-address.umbriel # https://github.com/picnoir
      ];
    };

    "partnerships@nixos.org" = {
      forwardTo = [
        ../../secrets/refroni-email-address.umbriel # https://github.com/refroni
      ];
    };

    "rob@nixos.org" = {
      forwardTo = [
        ../../secrets/rbvermaa-email-address.umbriel # https://github.com/rbvermaa
      ];
    };

    "ron@nixos.org" = {
      forwardTo = [
        ../../secrets/refroni-email-address.umbriel # https://github.com/refroni
      ];
    };

    "security@nixos.org" = {
      forwardTo = [
        ../../secrets/mweinelt-email-address.umbriel # https://github.com/mweinelt
        ../../secrets/risicle-email-address.umbriel # https://github.com/risicle
        ../../secrets/LeSuisse-email-address.umbriel # https://github.com/LeSuisse
      ];
    };

    "steering@nixos.org" = {
      forwardTo = [
        ../../secrets/Ericson2314-email-address.umbriel # https://github.com/Ericson2314
        ../../secrets/Gabriella439-email-address.umbriel # https://github.com/Gabriella439
        ../../secrets/fpletz-email-address.umbriel # https://github.com/fpletz
        ../../secrets/roberth-email-address.umbriel # https://github.com/roberth
        ../../secrets/tomberek-email-address.umbriel # https://github.com/tomberek
        ../../secrets/winterqt-email-address.umbriel # https://github.com/winterqt
        ../../secrets/jtojnar-email-address.umbriel # https://github.com/jtojnar
      ];
    };

    "summer@nixos.org" = {
      forwardTo = [
        ../../secrets/edolstra-summer-email-address.umbriel # https://github.com/edolstra
        ../../secrets/MMesch-email-address.umbriel # https://github.com/MMesch
        ../../secrets/bryanhonof-email-address.umbriel # https://github.com/bryanhonof
        ../../secrets/tomberek-email-address.umbriel # https://github.com/tomberek
        ../../secrets/gytis-ivaskevicius-email-address.umbriel # https://github.com/gytis-ivaskevicius
        ../../secrets/ysndr-email-address.umbriel # https://github.com/ysndr
        ../../secrets/DieracDelta-email-address.umbriel # https://github.com/DieracDelta
      ];
    };

    "sysadmin@nixos.org" = {
      forwardTo = [
        ../../secrets/edolstra-admin-email-address.umbriel # https://github.com/edolstra
        ../../secrets/zimbatm-admin-email-address.umbriel # https://github.com/zimbatm
      ];
    };

    "webmaster@nixos.org" = {
      forwardTo = [
        ../../secrets/edolstra-nixos-email-address.umbriel # https://github.com/edolstra
        ../../secrets/garbas-email-address.umbriel # https://github.com/garbas
      ];
    };
  };
}
