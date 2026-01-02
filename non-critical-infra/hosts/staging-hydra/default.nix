{ inputs, lib, ... }:
{
  imports = [
    ./hardware.nix
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.hardware-hetzner-cloud-arm
    ../../modules/common.nix
    ../../modules/hydra-queue-runner-v2.nix
    ../../modules/hydra-queue-builder-v2.nix
    ./hydra-proxy.nix
    ./hydra.nix
    inputs.hydra.nixosModules.hydra
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
