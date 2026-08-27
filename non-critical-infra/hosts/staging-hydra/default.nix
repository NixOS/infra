{ inputs, ... }:
{
  imports = [
    ./hardware.nix
    inputs.srvos.nixosModules.server
    ../../modules/common.nix
    ./hydra-proxy.nix
    ./hydra.nix
  ];

  nixpkgs.overlays = [
    inputs.hydra-staging.overlays.default
  ];

  disko.devices = import ./disko.nix;

  boot = {
    loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      mirroredBoots = [
        {
          devices = [ "nodev" ];
          path = "/boot";
        }
        {
          devices = [ "nodev" ];
          path = "/boot-fallback/1";
        }
        {
          devices = [ "nodev" ];
          path = "/boot-fallback/2";
        }
      ];
    };
    kernelParams = [ "console=tty" ];
  };

  networking = {
    hostName = "nixos";
    domain = "lysator.liu.se";
    hostId = "44230408"; # Needed for ZFS
    useDHCP = false;
  };

  systemd.network = {
    enable = true;
    networks."10-wan" = {
      address = [
        "130.236.254.207/24"
        "2001:6b0:17:f0a0::cf/64"
      ];

      dns = [
        "130.236.254.4"
        "130.236.254.225"
        "2001:6b0:17:f0a0::e1"
      ];

      linkConfig.RequiredForOnline = "routable";

      routes = [
        { Gateway = "130.236.254.1"; }
        { Gateway = "2001:6b0:17:f0a0::1"; }
      ];

      matchConfig.Path = "pci-0000:06:00.0";
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  networking.firewall.allowedUDPPorts = [ ];

  # Lysator admin account - DO NOT REMOVE
  users.users.lysroot = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF8WX07Oj1Mv9dIY6FaCdDdVQudVKJK6OSCRK8b16yzJ"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # Lysator syslog forwarding
  services.syslog-ng = {
    enable = true;
    extraConfig = ''
      source s_local {
        system();
        internal();
      };

      destination d_loghost {
        tcp("loghost.lysator.liu.se");
      };

      log {
        source(s_local);
        destination(d_loghost);
      };
    '';
  };

  services.fail2ban.enable = true;

  system.stateVersion = "25.11";

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
