{ config, ... }:

{
  imports = [ ./mailing-lists.nix ];

  mailserver = {
    enable = true;
    certificateScheme = "acme-nginx";

    # Until we have login accounts, there's no reason to run either of these.
    enablePop3 = false;
    enableImap = false;

    fqdn = config.networking.fqdn;

    # TODO: change to `nixos.org` when ready
    domains = [ "mail-test.nixos.org" ];
  };
}
