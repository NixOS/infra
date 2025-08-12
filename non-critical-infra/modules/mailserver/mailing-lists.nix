{
  imports = [ ./mailing-lists-options.nix ];

  # If you wish to hide your email address, you can encrypt it with SOPS. Just
  # run `nix run .#encrypt-email address -- --help` and follow the instructions.
  #
  # If you wish to set up a login account for sending/storing email, you must generate
  # an encrypted password. Run `nix run .#encrypt-email login -- --help` and
  # follow the instructions.
  mailing-lists = {
    # nixcon.org
    "orgateam@nixcon.org" = {
      forwardTo = [
        "nixcon@nixos.org"
      ];
    };

    # nixos.org
    "abuse@nixos.org" = {
      forwardTo = [
        "infra@nixos.org"
      ];
    };

    "finance@nixos.org" = {
      forwardTo = [
        ../../secrets/edolstra-email-address.umbriel # https://github.com/edolstra
      ];
      loginAccount = {
        encryptedHashedPassword = ../../secrets/finance-email-login.umbriel;
        storeEmail = true;
      };
    };

    "hardware@nixos.org" = {
      forwardTo = [
        "joerg.hardware@thalheim.io"
        ../../secrets/ra33it0-email-address.umbriel # https://github.com/Ra33it0
        ../../secrets/rosscomputerguy-email-address.umbriel # https://github.com/rosscomputerguy
      ];
      loginAccount = {
        encryptedHashedPassword = ../../secrets/hardware-email-login.umbriel;
        storeEmail = true;
      };
    };

    "foundation@nixos.org" = {
      forwardTo = [
        ../../secrets/edolstra-foundation-email-address.umbriel # https://github.com/edolstra
      ];
      loginAccount = {
        encryptedHashedPassword = ../../secrets/foundation-email-login.umbriel;
        storeEmail = true;
      };
    };

    "fundraising@nixos.org" = {
      forwardTo = [
        ../../secrets/fricklerhandwerk-email-address.umbriel # https://github.com/fricklerhandwerk
        "foundation@nixos.org"
      ];
    };

    "hexa@nixos.org" = {
      forwardTo = [
        ../../secrets/mweinelt-email-address.umbriel # https://github.com/mweinelt
      ];
      loginAccount = {
        encryptedHashedPassword = ../../secrets/hexa-email-login.umbriel;
        storeEmail = false;
      };
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
        ../../secrets/avocadoom-email-address.umbriel # https://discourse.nixos.org/u/avocadoom
        ../../secrets/djacu-email-address.umbriel # https://discourse.nixos.org/u/djacu
        ../../secrets/flyfloh-email-address.umbriel # https://discourse.nixos.org/u/flyfloh
      ];
    };

    "moderation@nixos.org" = {
      forwardTo = [
        ../../secrets/lassulus-email-address.umbriel # https://github.com/lassulus
        ../../secrets/uep-email-address.umbriel # https://discourse.nixos.org/u/uep
        ../../secrets/0x4A6F-moderation-email-address.umbriel # https://github.com/0x4A6F
        ../../secrets/aleksana-email-address.umbriel # https://github.com/aleksanaa
      ];
      loginAccount = {
        encryptedHashedPassword = ../../secrets/moderation-email-login.umbriel;
        storeEmail = true;
      };
    };

    "ngi@nixos.org" = {
      loginAccount = {
        encryptedHashedPassword = ../../secrets/ngi-nixos-org-email-login.umbriel;
        storeEmail = true;
      };
    };

    "nixcon@nixos.org" = {
      forwardTo = [
        ../../secrets/ners-email-address.umbriel # https://github.com/ners
        ../../secrets/john-rodewald-email-address.umbriel # https://github.com/john-rodewald
        ../../secrets/das-g-email-address.umbriel # https://github.com/das-g
        ../../secrets/ra33it0-email-address.umbriel # https://github.com/ra33it0
        ../../secrets/infinisil-nixcon-email-address.umbriel # https://github.com/infinisil
        ../../secrets/Nebucatnetzer-email-address.umbriel # https://github.com/Nebucatnetzer
        ../../secrets/andir-email-address.umbriel # https://github.com/andir
        ../../secrets/zmberber-email-address.umbriel # https://github.com/zmberber
        ../../secrets/a-kenji-email-address.umbriel # https://github.com/a-kenji
        ../../secrets/lassulus-nixcon-email-address.umbriel # https://github.com/lassulus
        ../../secrets/ForsakenHarmony-email-address.umbriel # https://github.com/ForsakenHarmony
        ../../secrets/picnoir-email-address.umbriel # https://github.com/picnoir
        ../../secrets/escherlies-email-address.umbriel # https://github.com/escherlies
        ../../secrets/fmehta-email-address.umbriel # https://github.com/fmehta
        ../../secrets/ral-email-address.umbriel # Matrix: @ral:fairydust.space
        ../../secrets/gefla-email-address.umbriel # https://github.com/gefla
      ];
      loginAccount = {
        encryptedHashedPassword = ../../secrets/nixcon-email-login.umbriel;
        storeEmail = true;
      };
    };

    "cfp@nixcon.org" = {
      forwardTo = [
        ../../secrets/ners-email-address.umbriel
        ../../secrets/ra33it0-email-address.umbriel
        ../../secrets/lassulus-nixcon-email-address.umbriel
        ../../secrets/a-kenji-email-address.umbriel
      ];
    };

    "partnerships@nixos.org" = {
      forwardTo = [
        ../../secrets/refroni-email-address.umbriel # https://github.com/refroni
      ];
    };

    "postmaster@nixos.org" = {
      forwardTo = [
        "infra@nixos.org"
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

    "sponsor@nixos.org" = {
      forwardTo = [
        "steering@nixos.org"
        "foundation@nixos.org"
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
        "infra@nixos.org"
      ];
    };

    "wiki@nixos.org" = {
      forwardTo = [
        ../../secrets/lassulus-wiki-email-address.umbriel # https://github.com/lassulus
        ../../secrets/Mic92-wiki-email-address.umbriel # https://github.com/Mic92
      ];
    };

    "winter@nixos.org" = {
      forwardTo = [
        ../../secrets/winterqt-email-address.umbriel # https://github.com/winterqt
      ];
    };

    "xsa@nixos.org" = {
      forwardTo = [
        ../../secrets/lach-xsa-email-address.umbriel # https://github.com/CertainLach
        ../../secrets/hehongbo-xsa-email-address.umbriel # https://github.com/hehongbo
        ../../secrets/sigmasquadron-xsa-email-address.umbriel # https://github.com/SigmaSquadron
      ];
    };
  };
}
