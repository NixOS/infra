{ nodes, config, lib, pkgs, ... }:

{
  imports =
    [ ./common.nix
      ./fstrim.nix
    ];

  deployment.targetEnv = "hetzner";
  deployment.hetzner.mainIPv4 = "46.4.66.184";

  # FIXME: manually changed nvme0n1p1 to a /boot disk. We can't use
  # GRUB on a RAID-0 disk because it doesn't support the "large_dir"
  # ext4 option.
  /*
  deployment.hetzner.partitions = ''
    clearpart --all --initlabel --drives=nvme0n1,nvme1n1

    part raid.1 --ondisk=nvme0n1 --size=16384
    part raid.2 --ondisk=nvme1n1 --size=16384

    part raid.3 --grow --ondisk=nvme0n1
    part raid.4 --grow --ondisk=nvme1n1

    raid swap --level=1 --device=md0 --fstype=swap --label=root raid.1 raid.2
    raid /    --level=1 --device=md1 --fstype=ext4 --label=root raid.3 raid.4
  '';
  */

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/boot";
      fsType = "ext4";
    };

  swapDevices = lib.mkForce [];

  networking = {
    firewall.allowedTCPPorts = [
      80 443
      9199 # hydra-notify's prometheus
    ];
    firewall.allowPing = true;
    firewall.logRefusedConnections = true;
  };

  # zramSwap.enable = true;

  nix.gc.automatic = true;
  nix.gc.options = ''--max-freed "$((400 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';
  nix.gc.dates = "03,09,15,21:15";

  nix.extraOptions = "gc-keep-outputs = false";

  networking.defaultMailServer.directDelivery = lib.mkForce false;
  #services.postfix.enable = true;
  #services.postfix.hostname = "hydra.nixos.org";

  # Don't rate-limit the journal.
  services.journald.rateLimitBurst = 0;
}
