{ inputs, lib, ... }:
{
  imports = [
    ./hardware.nix
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.hardware-hetzner-cloud-arm
    ../../modules/common.nix
    ./hydra-proxy.nix
    ./hydra.nix
  ];

  nixpkgs.overlays = [
    inputs.hydra.overlays.default
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      timeout = lib.mkForce 5;
      efi.efiSysMountPoint = "/efi";
    };
    kernelParams = [ "console=tty" ];
  };
  networking = {
    hostName = "staging-hydra";
    domain = "nixos.org";
  };

  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f9:c012:d5d3::1/128";

  disko.devices = import ./disko.nix;

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  networking.firewall.allowedUDPPorts = [ ];

  system.stateVersion = "24.11";
  users.users.root.openssh.authorizedKeys.keys = [
    # John Ericson for working on Hydra
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdof+fSLyz3FV5t/yE9LBk/hgR8iNfdz/DRigvh4pP6+E4VPpPKSeA0a8r4CLMWvy9ZZ3Gqa04NdJnMmo8gBSIlo87JPq66GnC5QmeDJX2NLlliSeNQqUQKJ2VVcsVerz8O/RvVfvU2MIdW8VExx/DxeZbMnwRcWfUC0nby0NotWGNeS3NOcWWQq9z4E0sDSJ+QXSIMXWSeMda5sBadUK+YERTLYE/+ZVUPiXkXCmnwuRFHpZsqlRVad+kgXsZIwNEPUEqmEablg2C0NjvEbs75Yu9WUXXPJNhwaFbVXaWUM8UWO/n39jMM8aepalZbMhdFh129cAH35SjzIYjHxTP"

    # Conni2461 for hydra-queue-runner
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPK/3rYhlIzoPCsPK38PMdK1ivqPaJgUqWwRtmxdKZrO"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEltgDXy2aiHhkNeL4aF7P9mDcpMR9+v8zo8EKUQUNHP"

    # picnoir for multiple signing keys
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPml1DaHG1i8WDEsbCCJwPRPf4wJWQAYQIYAyJh2zqMpAAAABHNzaDo="
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEPPocCK4JCbFWshVHMgICOm61LC6V2JAXThzKjXv7TSAAAABHNzaDo="
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEWWZ8LjNo41679gFI4Iv4YtjFxwhSbMZVsvvYYaTXdxAAAABHNzaDo= picnoir@framework"
  ];

  zramSwap = {
    enable = true;
    memoryPercent = 150;
  };
}
