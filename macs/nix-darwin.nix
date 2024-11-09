# used with https://github.com/DeterminateSystems/macos-ephemeral
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  sshKeys = rec {
    hydra-queue-runner = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOdxl6gDS7h3oeBBja2RSBxeS51Kp44av8OAJPPJwuU/ hydra-queue-runner@rhea";
  };
  environment = concatStringsSep " " [
    "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
  ];

  authorizedNixStoreKey =
    key:
    "command=\"${environment} ${config.nix.package}/bin/nix-store --serve --store daemon --write\" ${key}";
in

{
  environment.darwinConfig = "/nix/home/darwin-config/macs/nix-darwin.nix";
  environment.systemPackages = [ config.nix.package ];

  system.stateVersion = 5;

  programs.zsh.enable = true;
  programs.zsh.enableCompletion = false;
  programs.bash.enable = true;
  programs.bash.completion.enable = true;

  #services.activate-system.enable = true;

  services.nix-daemon.enable = true;

  nix.settings = {
    "extra-experimental-features" = [
      "nix-command"
      "flakes"
    ];
    max-jobs = 4;
    cores = 2;
  };

  nix.package = pkgs.nixVersions.nix_2_24.overrideAttrs (oldAttrs: {
    patches = oldAttrs.patches or [ ] ++ [ ./disable-chroot.patch ];
  });
  nix.gc.automatic = true;
  nix.gc.user = "";
  nix.gc.interval = {
    Minute = 15;
  };
  nix.gc.options =
    let
      gbFree = 50;
    in
    "--max-freed $((${toString gbFree} * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | awk '{ print $4 }')))";

  # If we drop below 20GiB during builds, free 20GiB
  nix.extraOptions = ''
    min-free = ${toString (30 * 1024 * 1024 * 1024)}
    max-free = ${toString (50 * 1024 * 1024 * 1024)}
  '';

  environment.etc."per-user/root/ssh/authorized_keys".text = concatStringsSep "\n" [
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
