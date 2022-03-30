{ nodes, config, lib, pkgs, ... }:
{
  imports =
    [ ./hardware-configuration.nix
      ./hetzner.nix
      ../common.nix
#      ../hydra.nix
#      ../hydra-proxy.nix
#      ../fstrim.nix
#      ../packet-importer.nix
    ];

  users.users.root.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKFclIiTNjds+cgXNGJOpNF+7t4U0WTHBzKsOZZ/9cSu" ];

  # This is a Hetzner machine, but when trying to set this machine up
  # I found the Hetzner NixOps plugin isn't able to create robot
  # sub-accounts, and even if I can get past that with
  # `createSubAccount = false`, the bootstrap tarball doesn't work.
  #
  # See: ./rhea/install.md for documentation about how I set it up by
  # hand.
  #deployment.targetEnv = "hetzner";
  #deployment.hetzner.mainIPv4 = "5.9.122.43";
  deployment.targetHost = "5.9.122.43";

  networking = {
    firewall.allowedTCPPorts = [
      80 443
      9199 # hydra-notify's prometheus
    ];
    firewall.allowPing = true;
    firewall.logRefusedConnections = false;
  };

  time.timeZone = lib.mkForce "UTC";
  system.stateVersion = lib.mkForce "21.11";
}

