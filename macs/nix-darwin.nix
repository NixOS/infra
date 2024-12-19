# used with https://github.com/DeterminateSystems/macos-ephemeral
{
  config,
  lib,
  pkgs,
  ...
}:

let
  sshKeys = {
    hydra-queue-runner = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOdxl6gDS7h3oeBBja2RSBxeS51Kp44av8OAJPPJwuU/ hydra-queue-runner@rhea";
  };
  environment = lib.concatStringsSep " " [
    "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
  ];

  authorizedNixStoreKey =
    key:
    "command=\"${environment} ${config.nix.package}/bin/nix-store --serve --store daemon --write\" ${key}";
in

{
  environment.darwinConfig = "/nix/home/darwin-config/macs/nix-darwin.nix";
  environment.systemPackages = [
    config.nix.package
    pkgs.nix-top
  ];

  system.stateVersion = 5;

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

  #services.activate-system.enable = true;

  services.nix-daemon.enable = true;

  nix = {
    package = pkgs.nixVersions.nix_2_24.overrideAttrs (oldAttrs: {
      patches = oldAttrs.patches or [ ] ++ [ ./disable-chroot.patch ];
    });
    settings = {
      # 8C/16G machines means 2C/4G per job on average
      cores = 2;
      max-jobs = 4;

      extra-experimental-features = [
        "nix-command"
        "flakes"
      ];
      max-silent-time = 7200; # 2h
      timeout = 43200; # 12h
    };
    gc = {
      automatic = true;
      user = "root";
      interval = {
        Minute = 15;
      };
      options =
        let
          gbFree = 100;
        in
        "--max-freed $((${toString gbFree} * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | awk '{ print $4 }')))";
    };
  };

  environment.etc."per-user/root/ssh/authorized_keys".text = lib.concatStringsSep "\n" [
    (authorizedNixStoreKey sshKeys.hydra-queue-runner)
  ];

  system.activationScripts.postActivation.text = ''
    printf "configuring ssh keys for hydra on the root account... "
    mkdir -p ~root/.ssh
    cp -f /etc/per-user/root/ssh/authorized_keys ~root/.ssh/authorized_keys
    chown root:wheel ~root ~root/.ssh ~root/.ssh/authorized_keys
    echo "ok"
  '';

  services.prometheus.exporters.node.enable = true;

  launchd.daemons.rosetta2-gc = {
    script = ''
      date
      exec /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -P -minsize 0 /System/Volumes/Data
    '';
    serviceConfig.StartInterval = 3600 * 2;
    serviceConfig.RunAtLoad = true;
    serviceConfig.StandardErrorPath = "/var/log/rosetta2-gc.log";
    serviceConfig.StandardOutPath = "/var/log/rosetta2-gc.log";
  };
}
