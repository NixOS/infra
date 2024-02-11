{ nodes, config, lib, pkgs, ... }:
{
  imports =
    [ ./hardware-configuration.nix
      ./hetzner.nix
      ./network.nix
      ../common.nix
      ../hydra.nix
      ../hydra-proxy.nix
      ../hydra-scaler.nix
      ../packet-importer.nix
    ];

  networking = {
    hostName = "rhea";
    firewall.allowedTCPPorts = [
      80 443
      9198 # hydra-queue-runner's prometheus
      9199 # hydra-notify's prometheus
    ];
    firewall.allowPing = true;
    firewall.logRefusedConnections = false;
  };

  time.timeZone = lib.mkForce "UTC";
  system.stateVersion = "21.11";

  services.hydra-dev.dbi = "dbi:Pg:dbname=hydra;host=10.254.1.9;user=hydra;";
  systemd.services.hydra-init = {
    after = [ "wireguard-wg0.service" ];
    requires = [ "wireguard-wg0.service" ];
  };
  systemd.services.hydra-queue-runner = {
    serviceConfig.ManagedOOMPreference = "avoid";
  };
  services.hydra-dev.buildMachinesFiles = [ "/etc/nix/machines" ];

  # hydra-evaluator causes very sharp spikes in RAM usage on trunk-combined
  zramSwap.enable = true;

  nix.gc.automatic = true;
  nix.gc.options = ''--max-freed "$((400 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';
  nix.gc.dates = "03,09,15,21:15";

  nix.extraOptions = "gc-keep-outputs = false";

  #services.postfix.enable = true;
  #services.postfix.hostname = "hydra.nixos.org";

  # Don't rate-limit the journal.
  services.journald.rateLimitBurst = 0;
}
