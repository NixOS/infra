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
      loginAccount = {
        encryptedHashedPassword = ../../secrets/finance-email-login.umbriel;
        storeEmail = true;
      };
    };

    "hardware@nixos.org" = {
      forwardTo = [
        "joerg.hardware@thalheim.io"
        ../../secrets/0x4A6F-hardware-email-address.umbriel # https://github.com/0x4A6F
        ../../secrets/ra33it0-email-address.umbriel # https://github.com/Ra33it0
        ../../secrets/rosscomputerguy-email-address.umbriel # https://github.com/rosscomputerguy
      ];
      loginAccount = {
        encryptedHashedPassword = ../../secrets/hardware-email-login.umbriel;
        storeEmail = true;
      };
    };

    "foundation@nixos.org" = {
      loginAccount = {
        encryptedHashedPassword = ../../secrets/foundation-email-login.umbriel;
        storeEmail = true;
      };
    };

    "fundraising@nixos.org" = {
      forwardTo = [
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
      loginAccount = {
        encryptedHashedPassword = ../../secrets/nixcon-email-login.umbriel;
        storeEmail = true;
      };
    };

    "cfp@nixcon.org" = {
      forwardTo = [
        "nixcon@nixos.org"
      ];
    };

    "partnerships@nixos.org" = {
      forwardTo = [
        "foundation@nixos.org"
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
        ../../secrets/roberth-email-address.umbriel # https://github.com/roberth
        ../../secrets/tomberek-email-address.umbriel # https://github.com/tomberek
        ../../secrets/winterqt-email-address.umbriel # https://github.com/winterqt
        ../../secrets/jtojnar-email-address.umbriel # https://github.com/jtojnar
      ];
      loginAccount = {
        encryptedHashedPassword = ../../secrets/steering-email-login.umbriel;
        storeEmail = true;
      };
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
