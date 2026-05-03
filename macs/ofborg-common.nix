{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./ofborg.nix
    ./ofborg-queue-builder.nix
  ];

  environment.systemPackages = [
    config.nix.package
    pkgs.nix-top
  ];

  system.stateVersion = 5;
  ids.gids.nixbld = 30000;

  programs = {
    zsh = {
      enable = true;
      enableCompletion = false;
    };
    bash = {
      enable = true;
      completion.enable = true;
    };
  };

  nix = {
    settings = {
      extra-experimental-features = [
        "nix-command"
        "flakes"
      ];
      max-silent-time = 7200; # 2h
      timeout = 43200; # 12h
    };
    gc = {
      automatic = true;
      interval = {
        # hourly at the 15th minute
        Minute = 15;
      };
      # ensure up to 125G free space every hour
      options = "--max-freed $(df -k /nix/store | awk 'NR==2 {available=$4; required=125*1024*1024; to_free=required-available; printf \"%.0d\", to_free*1024}')";
    };
  };

  # Manage user for ofborg, this enables creating/deleting users
  # depending on what modules are enabled.
  users = {
    users.ofborg.home = "/private/var/lib/ofborg";
    users.root = {
      # bash doesn't export /run/current-system/sw/bin to $PATH,
      # which we need for nix-store
      shell = "/bin/zsh";
      # Not part of the infra team
      openssh.authorizedKeys.keys = (import ../ssh-keys.nix).infra ++ [
        # Not part of the infra team
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM35Bq87SBWrEcoDqrZFOXyAmV/PJrSSu3hl3TdVvo4C janne"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPK/3rYhlIzoPCsPK38PMdK1ivqPaJgUqWwRtmxdKZrO ✏️"
      ];
    };
  };

  system.activationScripts.postActivation.text = ''
    printf "disabling spotlight indexing... "
    mdutil -i off -d / &> /dev/null
    mdutil -E / &> /dev/null
    echo "ok"
  '';

  services.prometheus.exporters.node.enable = true;
  # https://github.com/LnL7/nix-darwin/issues/1256
  users.users._prometheus-node-exporter.home = lib.mkForce "/private/var/lib/prometheus-node-exporter";
}
