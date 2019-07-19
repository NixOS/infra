{ nodes, config, lib, pkgs, ... }:

{
  imports =
    [ ./common.nix
      ./hydra.nix
      ./hydra-proxy.nix
      ./fstrim.nix
      ../modules/wireguard.nix
      ./packet-importer.nix
    ];

  deployment.targetEnv = "hetzner";
  deployment.hetzner.mainIPv4 = "46.4.66.184";

  deployment.hetzner.partitions = ''
    clearpart --all --initlabel --drives=nvme0n1,nvme1n1

    part raid.1 --ondisk=nvme0n1 --size=16384
    part raid.2 --ondisk=nvme1n1 --size=16384

    part raid.3 --grow --ondisk=nvme0n1
    part raid.4 --grow --ondisk=nvme1n1

    raid swap --level=1 --device=md0 --fstype=swap --label=root raid.1 raid.2
    raid /    --level=1 --device=md1 --fstype=ext4 --label=root raid.3 raid.4
  '';

  networking = {
    firewall.allowedTCPPorts = [ 80 443 ];
    firewall.allowPing = true;
    firewall.logRefusedConnections = true;
  };

  services.hydra-dev.dbi = "dbi:Pg:dbname=hydra;host=10.254.1.2;user=hydra;";

  nix.gc.automatic = true;
  nix.gc.options = ''--max-freed "$((100 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';
  nix.gc.dates = "03,09,15,21:15";

  nix.extraOptions = "gc-keep-outputs = false";

  networking.defaultMailServer.directDelivery = lib.mkForce false;
  #services.postfix.enable = true;
  #services.postfix.hostname = "hydra.nixos.org";

  # Don't rate-limit the journal.
  services.journald.rateLimitBurst = 0;
}
