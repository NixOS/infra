{
  imports = [
    ./hardware-configuration.nix
    ./hetzner.nix
    ./network.nix
    ../common.nix
  ];

  networking = {
    hostName = "rhea";
    firewall.allowPing = true;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIY0EGPGfXD1L+YdSJIKUzeFyuUfVW58kMh+mSflEFx1 root@mimas"
  ];

  system.stateVersion = "21.11";

  systemd.services.hydra-init = {
    after = [ "wireguard-wg0.service" ];
    requires = [ "wireguard-wg0.service" ];
  };

  # hydra-evaluator causes very sharp spikes in RAM usage on trunk-combined
  zramSwap.enable = true;
  zramSwap.memoryPercent = 150;
}
