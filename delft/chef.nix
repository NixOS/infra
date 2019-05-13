{ config, lib, pkgs, ...}:

{
  imports =
    [ ./common.nix
      ./hydra.nix
      ./hydra-proxy.nix
      ./datadog.nix
      ./fstrim.nix
      ./provisioner.nix
      ../modules/wireguard.nix
      ./packet-importer.nix
    ];

  deployment.targetEnv = "hetzner";
  deployment.hetzner.mainIPv4 = "46.4.67.10";

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql95;
    extraConfig = ''
      log_min_duration_statement = 5000
      log_duration = off
      log_statement = 'none'
      max_connections = 250
      work_mem = 16MB
      shared_buffers = 2GB

      # Checkpoint every 256 MB.
      min_wal_size = 128MB
      max_wal_size = 256MB

      # We can risk losing some transactions.
      synchronous_commit = off

      effective_cache_size = 16GB
    '';
  };

  networking = {

    firewall.allowedTCPPorts = [ 80 443 ];
    firewall.allowPing = true;
    firewall.logRefusedConnections = true;

  };

  nix.gc.automatic = true;
  nix.gc.options = ''--max-freed "$((100 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';
  nix.gc.dates = "03,09,15,21:15";

  nix.extraOptions = "gc-keep-outputs = false";

  networking.defaultMailServer.directDelivery = lib.mkForce false;
  #services.postfix.enable = true;
  #services.postfix.hostname = "hydra.nixos.org";

  # Don't rate-limit the journal.
  services.journald.rateLimitBurst = 0;

  fileSystems."/data" =
    { device = "/dev/disk/by-label/data";
      fsType = "ext4";
    };

}
