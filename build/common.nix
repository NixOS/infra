{
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./diffoscope.nix
    ../modules/common.nix
    ../modules/nftables.nix
    ../modules/prometheus
    ../modules/rasdaemon.nix
  ];

  nixpkgs.config.allowUnfree = true;

  hardware.enableAllFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  hardware.cpu.intel.updateMicrocode = true;

  boot.kernel.sysctl = {
    # reboot on kernel panic
    "kernel.panic" = 60;
    "kernel.panic_on_oops" = 1;
  };

  documentation.nixos.enable = false;

  environment = {
    enableDebugInfo = true;
    systemPackages = with pkgs; [
      # debugging
      gdb
      lsof
      sqlite-interactive

      # editors
      helix
      neovim

      # utilities
      ripgrep
      fd

      # system introspection
      dmidecode
      hdparm
      htop
      iotop
      lm_sensors
      nvme-cli
      powerstat
      smartmontools
      sysstat
      tcpdump
      tmux
    ];
  };

  services.openssh = {
    enable = true;
    authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
  };

  nix.extraOptions = ''
    allowed-impure-host-deps = /etc/protocols /etc/services /etc/nsswitch.conf
    allowed-uris = https://github.com/ https://git.savannah.gnu.org/ github:
  '';

  # we use networkd
  networking.useDHCP = false;

  services.resolved = {
    enable = true;
    fallbackDns = [
      # https://docs.hetzner.com/de/dns-console/dns/general/recursive-name-servers/
      "185.12.64.1"
      "185.12.64.2"
      "2a01:4ff:ff00::add:1"
      "2a01:4ff:ff00::add:2"
    ];
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "infra@nixos.org";
  };

  services.zfs.autoScrub.enable = true;
}
