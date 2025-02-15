{ inputs, lib, ... }:
{
  imports = [
    ./hardware.nix
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.hardware-hetzner-cloud-arm
    ../../modules/common.nix
    ./hydra-proxy.nix
    ./hydra.nix
    inputs.hydra.nixosModules.hydra
  ];

  nixpkgs.overlays = [
    inputs.nix.overlays.default
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
    # m1-s
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINaGspw6myJ5GKHHxN+7jaJWyU1SlVo4nCzDajyJdtvg"
  ];
}
