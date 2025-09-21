{ pkgs, ... }:

{
  imports = [
    ../../modules/nftables.nix
  ];

  boot.initrd.systemd.enable = true;

  time.timeZone = "UTC";

  systemd.services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = (import ../../ssh-keys.nix).infra;

  environment.systemPackages = with pkgs; [ neovim ];

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "infra@nixos.org";
}
