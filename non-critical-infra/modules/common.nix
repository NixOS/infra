{ pkgs, ... }:

{
  imports = [
    ../../modules/nftables.nix
    ../../modules/prometheus
  ];

  boot.initrd.systemd.enable = true;
  boot.zfs.forceImportRoot = false;

  time.timeZone = "UTC";

  systemd.services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = (import ../../keys.nix).ssh.groups.infra;

  environment.systemPackages = with pkgs; [ neovim ];

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "infra@nixos.org";
}
