flakes @ { self, nixpkgs, nix, nixops, nixos-channel-scripts }:

{ modulesPath, config, lib, pkgs, ... }:
let
  sshKeys = import ../ssh-keys.nix;
in
{
  imports = [
    ../modules/common.nix
    ../modules/hydra-mirror.nix
    ../modules/prometheus
    ../modules/tarball-mirror.nix
    ../modules/wireguard.nix
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  ec2.hvm = true;

  networking.hostName = "bastion";

  system.configurationRevision = flakes.self.rev
    or (throw "Cannot deploy from an unclean source tree!");

  nix.registry.nixpkgs.flake = flakes.nixpkgs;
  nix.nixPath = [ "nixpkgs=${flakes.nixpkgs}" ];
  nix.trustedUsers = [ "deploy" ];

  nixpkgs.overlays = [
    nix.overlay
    nixops.overlay
    nixos-channel-scripts.overlay
  ];

  users.extraUsers.tarball-mirror.openssh.authorizedKeys.keys = [ sshKeys.eelco ];

  users.extraUsers.deploy = {
    description = "NixOps deployments";
    isNormalUser = true;
    openssh.authorizedKeys.keys =
      [ sshKeys.eelco sshKeys.rob sshKeys.graham sshKeys.zimbatm sshKeys.amine ];
    extraGroups = [ "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = [
    pkgs.awscli
    pkgs.nixops
    pkgs.terraform-full
    pkgs.tmux
  ];

  nix.gc.automatic = true;
  nix.gc.dates = "daily";
  nix.gc.options = ''--max-freed "$((30 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';

  services.openssh.enable = true;

  # Temporary hack until we have proper users/roles.
  services.openssh.extraConfig = ''
    AcceptEnv AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY FASTLY_API_KEY GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
  '';

  fileSystems."/scratch" = {
    autoFormat = true;
    fsType = "ext4";
    device = "/dev/nvme1n1";
  };

  # work around releases taking too much memory
  swapDevices = [{ device = "/scratch/swapfile"; size = 32 * 1024; }];

  # Enable swap so mirroring the channels doesn't make AWS think this machine is dead
  boot.kernel.sysctl."vm.swappiness" = lib.mkDefault 60;

  boot.loader.grub.device = lib.mkForce "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol0631f5232321abda4";

  systemd.tmpfiles.rules = [ "d /scratch/hydra-mirror 0755 hydra-mirror users 10d" ];
}
