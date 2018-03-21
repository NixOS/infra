{ config, lib, pkgs, ... }:

with lib;

let
  environment = concatStringsSep " "
    [
      "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
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
  nix.gc.automatic = true;
  nix.gc.options = "--max-freed $((25 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | awk '{ print $4 }')))";

  environment.etc."per-user/root/ssh/authorized_keys".text = concatStringsSep "\n"
    [ "command=\"${environment} ${config.nix.package}/bin/nix-store --serve --write\" ssh-dss AAAAB3NzaC1kc3MAAACBAMHRjGSDaBp4Z30JF4S9ApabBCpdr57Ad0aD9oH2A/WEFnWYQSAzK4E/HHD2DV2XP1stNkZ1ks2v3F4Yu/veR+qVlUWbJW1RIIfuQgkG44K0R3C2qx4BAZUVYzju1NVCJbBOO6ipVY9cfmpokV52HZFhP/2HocTNLoav3F0AsbbJAAAAFQDaJiQdpJBEa4Wr5FfVl1kYqmQZJwAAAIEAwbern5XL+SNIMa+sJ3CBhrWyYExYWiUbdmhQEfyEAUmoPsEr1qpb+0WREic9Nrxz48QWZDK5xMvzZyQEkuAMJUBWcdm12rME7WMvg7OZGr9DADjAtfMfj3Ui2XvOuQ3ia/OTsMGkQTDWnkOM9Ni128SNSl9urFBlXATdGvo+468AAACBAK8s6LddhhkRqsF/l/L2ooS8c8A1rTFWAOy3/sgXFNvMyS/Mig2p966xRrRHr7Bc+H2SuKEE5WmLCXqymgxLHhrFU4zm/W/ej1yB1CAThd4xUfgJu4touJROjvcD1zzlmLeat0fp2k5mCuiLKcTKi0vxKWiiopF9nvBBK+7ODPC7 buildfarm@nixos"
      "command=\"${environment} ${config.nix.package}/bin/nix-store --serve --write\" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyM48VC5fpjJssLI8uolFscP4/iEoMHfkPoT9R3iE3OEjadmwa1XCAiXUoa7HSshw79SgPKF2KbGBPEVCascdAcErZKGHeHUzxj7v3IsNjObouUOBbJfpN4DR7RQT28PZRsh3TvTWjWnA9vIrSY/BvAK1uezFRuObvatqAPMrw4c0DK+JuGuCNkKDGHLXNSxYBc5Pmr1oSU7/BDiHVjjyLIsAMIc20+q8SjWswKqL1mY193mN7FpUMBtZrd0Za9fMFRII9AofEIDTOayvOZM6+/1dwRWZXM6jhE6kaPPF++yromHvDPBnd6FfwODKLvSF9BkA3pO5CqrD8zs7ETmrV hydra-queue-runner@chef"
    ];


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
