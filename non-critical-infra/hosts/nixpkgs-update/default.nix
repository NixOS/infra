{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.hardware-hetzner-online-amd
    ../../modules/common.nix
    ../../modules/nginx.nix
    ../../modules/nixpkgs-update
    ../../modules/nixpkgs-update/backup.nix
    ../../modules/nixpkgs-update/cache.nix
  ];

  disko.devices = import ./disko.nix { inherit lib; };

  nixpkgs.hostPlatform = "x86_64-linux";

  # Keep the host key of the previous installation: the sops age key is derived
  # from it.
  services.openssh.hostKeys = [
    {
      path = "/var/lib/ssh_secrets/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];
  sops.age.sshKeyPaths = [ "/var/lib/ssh_secrets/ssh_host_ed25519_key" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "nixpkgs-update";
    domain = "nixos.org";
    # required by ZFS; pinned to the value derived from the old hostname "build02"
    hostId = "8425e349";
  };

  # using latest for mimalloc
  nix.package = pkgs.nixVersions.latest;

  nix.settings.auto-optimise-store = lib.mkForce false;
  nix.settings.cores = config.nix.settings.max-jobs / 3 * 2;
  nix.settings.max-jobs = 24;

  boot.kernelParams = [ "zfs.zfs_arc_max=${toString (24 * 1024 * 1024 * 1024)}" ]; # 24GB, try to limit OOM kills / reboots

  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];

  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f9:3b:41d9::1";

  system.stateVersion = "23.11";
}
