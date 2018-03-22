{ config, lib, pkgs, ... }:

with lib;

let
  sshKeys = import ../ssh-keys.nix;

  environment = concatStringsSep " "
    [
      "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];

   authorizedNixStoreKey = key:
      "command=\"${environment} ${config.nix.package}/bin/nix-store --serve --write\" ${key}";
in

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [
      config.nix.package
    ];

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.bash.enable = true;
  programs.bash.enableCompletion = false;

  # Recreate /run/current-system symlink after boot.
  services.activate-system.enable = true;

  services.nix-daemon.enable = true;

  nix.package = pkgs.nixUnstable;
  # Should we enable this to not cache false negatives?
  # nix.binaryCaches = lib.mkForce [ https://nix-cache.s3.amazonaws.com/ ];

  nix.maxJobs = 4;
  nix.buildCores = 1;
  nix.gc.automatic = true;
  nix.gc.options = let
      gbFree = 25;
    in "--max-freed $((${toString gbFree} * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | awk '{ print $4 }')))";

  environment.etc."per-user/root/ssh/authorized_keys".text = concatStringsSep "\n"
    ([(authorizedNixStoreKey sshKeys.build-farm)
      (authorizedNixStoreKey sshKeys.hydra-queue-runner)
      ] ++ sshKeys.mac_keys);


  system.activationScripts.preActivation.text = ''
    printf "setting up /run... "
    if [ ! -L /run ]; then
        sudo ln -s /private/var/run /run
    fi
    echo "ok"

    if ! test -L /etc/profile && grep -q 'etc/profile.d/nix-daemon.sh' /etc/profile; then
        printf "removing nix-daemon from /etc/profile... "
        sudo patch -d /etc -p1 < '${./profile.patch}'
        echo "ok"
    fi

    if [ ! -f /etc/bashrc.old ]; then
      printf "moving the bashrc out of the way... "
      mv /etc/bashrc /etc/bashrc.old
      echo "ok"
    fi
    if [ ! -f /etc/nix/nix.conf.old ]; then
      printf "moving the nix.conf out of the way... "
      mv /etc/nix/nix.conf /etc/nix/nix.conf.old
      echo "ok"
    fi
  '';


  system.activationScripts.postActivation.text = ''
    printf "disabling spotlight indexing... "
    mdutil -i off -d / &> /dev/null
    mdutil -E / &> /dev/null
    echo "ok"

    printf "configuring ssh keys for hydra on the root account... "
    mkdir -p ~root/.ssh
    cp -f /etc/per-user/root/ssh/authorized_keys ~root/.ssh/authorized_keys
    chown root:wheel ~root ~root/.ssh ~root/.ssh/authorized_keys
    echo "ok"
  '';
}
