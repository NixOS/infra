{
  lib,
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    ../common.nix
    ./boot.nix
    ./network.nix
    ./postgresql.nix
  ];

  networking = {
    hostId = "83c81a23";
    hostName = "haumea";
    domain = "nixos.org";
  };

  environment.systemPackages = [ pkgs.lz4 ];

  fileSystems."/" = {
    device = "rpool/safe/root";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot0";
    fsType = "ext4";
  };

  fileSystems."/nix" = {
    device = "rpool/local/nix";
    fsType = "zfs";
  };

  fileSystems."/var/db/postgresql" = {
    device = "rpool/safe/postgres";
    fsType = "zfs";
  };

  services.zfs.autoScrub.enable = true;

  nix.settings.max-jobs = lib.mkDefault 16;

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  system.stateVersion = "14.12";
}
