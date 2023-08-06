{ config, pkgs, lib, inputs, ... }:

{
  imports =
    [
      ./hardware.nix
      inputs.srvos.nixosModules.server
      inputs.srvos.nixosModules.hardware-hetzner-online-amd
    ];


  deployment = {
    targetHost = "65.109.26.213";
    targetUser = "root";
  };

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.loader.grub.mirroredBoots = [
    { path = "/boot-1"; devices = [ "/dev/disk/by-id/nvme-SAMSUNG_MZQL23T8HCLS-00A07_S64HNJ0T508051" ]; }
    { path = "/boot-2"; devices = [ "/dev/disk/by-id/nvme-SAMSUNG_MZQL23T8HCLS-00A07_S64HNJ0T508053" ]; }
  ];
  boot.loader.grub.useOSProber = true;


  networking.hostName = "hetzner-01"; # Define your hostname.
  networking.hostId = "745b334a";

  disko.devices = import ./disko.nix;

  # Set your time zone.
  time.timeZone = "UTC";

  environment.systemPackages = with pkgs; [
    neovim
  ];

  services.openssh.enable = true;

  networking.firewall.allowedTCPPorts = [ ];
  networking.firewall.allowedUDPPorts = [ ];

  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f9:5a:186c::2";

  users.users.root.openssh.authorizedKeys.keyFiles = [
    (pkgs.fetchurl {
      url = "https://github.com/JulienMalka.keys";
      sha256 = "sha256-yH84N5aPt9MJDuvaDf9BvnM+z9yaUKYxU7W2Bf89174=";
    })
    (pkgs.fetchurl {
      url = "https://github.com/zimbatm.keys";
      sha256 = "sha256-QEOYK1aoF626VTTjlcFtY020NSCfiCnBRQfrNfl0j5s=";
    })
    (pkgs.fetchurl {
      url = "https://github.com/mweinelt.keys";
      sha256 = "sha256-gAD2jUc5SBWuuiRGgJEmb0I7rR/jti1FMxVuA0BtILk=";
    })
  ];

  system.stateVersion = "23.05";

}

