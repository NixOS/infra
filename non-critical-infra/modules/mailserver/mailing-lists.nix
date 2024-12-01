# This module makes it easy to define mailing lists in `simple-nixos-mailserver`
# with a couple of features:
#
#  1. We can (optionally) encrypt the forward addresses for increase privacy.
#  2. We can set up a login account for mailing addresses to allow sending
#     email via `SMTP` from those addresses.

{ config, lib, ... }:

let
  inherit (lib) types;

  fileToSecretId = file: builtins.baseNameOf file;

  listsWithSecretPlaceholders = lib.mapAttrs' (name: mailingList: {
    name = name;
    value = map (
      member:
      if builtins.isString member then member else config.sops.placeholder.${fileToSecretId member}
    ) mailingList.forwardTo;
  }) config.mailing-lists;

  secretAddressFiles = lib.pipe config.mailing-lists [
    (lib.mapAttrsToList (_name: mailingList: mailingList.forwardTo))
    lib.flatten
    (builtins.filter (member: !builtins.isString member))
  ];

  secretPasswordFiles = lib.pipe config.mailing-lists [
    (lib.filterAttrs (_name: mailingList: mailingList.loginAccount != null))
    (lib.mapAttrsToList (_name: mailingList: mailingList.loginAccount.encryptedHashedPassword))
  ];
in

{
  options = {
    mailing-lists = lib.mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            forwardTo = lib.mkOption {
              type = types.listOf (types.either types.str types.path);
              description = ''
                Either a plaintext email address, or a path to an email address
                encrypted with `nix run .#encrypt-email address`
              '';
            };
            loginAccount = lib.mkOption {
              type = types.nullOr (
                types.submodule {
                  options = {
                    encryptedHashedPassword = lib.mkOption {
                      type = types.path;
                      description = ''
                        If specified, this enables sending emails from this address via SMTP.
                        Must be a path to encrypted file generated with `nix run .#encrypt-email login`
                      '';
                    };
                  };
                }
              );
              default = null;
            };
          };
        }
      );
      description = ''
        Mailing lists. Supports both forward-only mailing lists, as well as mailing
        lists that allow sending via SMTP.
      '';
    };
  };

  config = {
    # Disable IMAP. We don't need it, as we don't store email on this server, we
    # only forward emails.
    mailserver.enableImap = false;
    mailserver.enableImapSsl = false;
    services.dovecot2.enableImap = false;

    mailserver.loginAccounts = lib.pipe config.mailing-lists [
      (lib.filterAttrs (_name: mailingList: mailingList.loginAccount != null))
      (lib.mapAttrs (
        _name: mailingList: {
          hashedPasswordFile =
            config.sops.secrets.${fileToSecretId mailingList.loginAccount.encryptedHashedPassword}.path;
        }
      ))
    ];

    # Declare secrets for every secret file.
    sops.secrets = builtins.listToAttrs (
      (map (file: {
        name = fileToSecretId file;
        value = {
          format = "binary";
          sopsFile = file;
        };
      }) secretAddressFiles)
      ++ (map (file: {
        name = fileToSecretId file;
        value = {
          format = "binary";
          sopsFile = file;
          # Need to restart `dovecot2.service` to trigger `genPasswdScript` in
          # `nixos-mailserver`:
          # https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/blob/af7d3bf5daeba3fc28089b015c0dd43f06b176f2/mail-server/dovecot.nix#L369
          # This could go away if sops-nix gets support for "input addressed secret
          # paths": https://github.com/Mic92/sops-nix/issues/648
          restartUnits = [ "dovecot2.service" ];
        };
      }) secretPasswordFiles)
    );

    sops.templates."postfix-virtual-mailing-lists" = {
      content = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: members: "${name} ${lib.concatStringsSep ", " members}"
        ) listsWithSecretPlaceholders
      );

      # Need to restart postfix-setup to rerun `postmap` and generate updated `.db`
      # files whenever mailing list membership changes.
      # This could go away if sops-nix gets support for "input addressed secret
      # paths": https://github.com/Mic92/sops-nix/issues/648
      restartUnits = [ "postfix-setup.service" ];
    };

    services.postfix.mapFiles.virtual-mailing-lists =
      config.sops.templates."postfix-virtual-mailing-lists".path;

    services.postfix.config.virtual_alias_maps = [ "hash:/etc/postfix/virtual-mailing-lists" ];
  };
}
