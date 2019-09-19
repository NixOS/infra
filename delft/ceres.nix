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
    firewall.allowedTCPPorts = [ 80 443 ];
    firewall.allowPing = true;
    firewall.logRefusedConnections = true;
  };

  services.hydra-dev.dbi = "dbi:Pg:dbname=hydra;host=10.254.1.2;user=hydra;";
  #systemd.services.hydra-init.wants = [ "sys-devices-virtual-net-wg0.device" ];

  services.hydra-dev.buildMachinesFiles = [ "/etc/nix/machines" ];

  nix.gc.automatic = true;
  nix.gc.options = let
    calculator = pkgs.writeShellScript "calculate-bytes-free"
      ''
        PATH=${pkgs.gawk}/bin:$PATH

        wantedGigabytesFree=400
        wantedInodesPercentFree=25
        # Estimate how many megabytes will prune 1% of inodes. Doesn't
        # have to be very exact.
        megabytesPerPercent=500

        diskSpaceAvailableKb=$(df -P -k /nix/store | tail -n1 | awk '{ print $4; }')
        inodesPercentUsed=$(df -P -i /nix/store | tail -n1 | awk '{ print $5; }' | sed -e 's/%$//')

        wantedBytesFree=$((wantedGigabytesFree * 1024**3))
        toFreeForBytes=$((wantedBytesFree - 1024 * diskSpaceAvailableKb))
        if [ $toFreeForBytes -lt 0 ]; then
          toFreeForBytes=0
        fi

        inodesHighWaterMark=$((100 - wantedInodesPercentFree))
        bytesPerPercent=$((megabytesPerPercent * 1024**2))
        inodesPercentOverBudget=$((inodesPercentUsed - inodesHighWaterMark));

        if [ $inodesPercentOverBudget -gt 0 ]; then
          toFreeForInodes=$((inodesPercentOverBudget * bytesPerPercent))
        else
          toFreeForInodes=0
        fi

        echo $((toFreeForBytes + toFreeForInodes))
      '';
  in ''--max-freed "$(${calculator})"'';
  nix.gc.dates = "03,09,15,21:15";

  nix.extraOptions = "gc-keep-outputs = false";

  networking.defaultMailServer.directDelivery = lib.mkForce false;
  #services.postfix.enable = true;
  #services.postfix.hostname = "hydra.nixos.org";

  # Don't rate-limit the journal.
  services.journald.rateLimitBurst = 0;
}
