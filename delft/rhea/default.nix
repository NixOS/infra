{ nodes, config, lib, pkgs, ... }:
{
  imports =
    [ ./hardware-configuration.nix
      ./hetzner.nix
      ../common.nix
      ../hydra.nix
      ../hydra-proxy.nix
      ../hydra-scaler.nix
      ../packet-importer.nix
    ];

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
      9198 # hydra-queue-runner's prometheus
      9199 # hydra-notify's prometheus
    ];
    firewall.allowPing = true;
    firewall.logRefusedConnections = false;
  };

  time.timeZone = lib.mkForce "UTC";
  system.stateVersion = lib.mkForce "21.11";

  services.hydra-dev.dbi = "dbi:Pg:dbname=hydra;host=10.254.1.9;user=hydra;";
  systemd.services.hydra-init = {
    after = [ "wireguard-wg0.service" ];
    requires = [ "wireguard-wg0.service" ];
  };
  systemd.services.hydra-queue-runner = {
    serviceConfig.ManagedOOMPreference = "avoid";
  };
  services.hydra-dev.buildMachinesFiles = [ "/etc/nix/machines" ];

  nix.gc.automatic = true;
  nix.gc.options = ''--max-freed "$((400 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';
  nix.gc.dates = "03,09,15,21:15";

  nix.extraOptions = "gc-keep-outputs = false";

  #services.postfix.enable = true;
  #services.postfix.hostname = "hydra.nixos.org";

  # Don't rate-limit the journal.
  services.journald.rateLimitBurst = 0;
}
