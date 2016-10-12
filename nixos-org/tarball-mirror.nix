# This module mirrors most tarballs reachable from Nixpkgs's
# release.nix to the content-addressed tarball cache at
# tarballs.nixos.org.

{ config, lib, pkgs, ... }:

with lib;

let

  nixosRelease = "16.09";

in

{

  users.extraUsers.tarball-mirror =
    { description = "Nixpkgs tarball mirroring user";
      home = "/home/tarball-mirror";
      isNormalUser = true;
      openssh.authorizedKeys.keys = with import ../ssh-keys.nix; [ eelco ];
    };

  systemd.services.mirror-tarballs =
    { description = "Mirror Nixpkgs Tarballs";
      path  = [ config.nix.package pkgs.git pkgs.bash ];
      environment.NIX_REMOTE = "daemon";
      serviceConfig.User = "tarball-mirror";
      serviceConfig.Type = "oneshot";
      serviceConfig.PrivateTmp = true;
      script =
        ''
          cd /home/tarball-mirror/nixpkgs
          git remote update channels
          git checkout channels/nixos-${nixosRelease}
          # FIXME: use IAM role.
          export AWS_ACCESS_KEY_ID=$(sed 's/aws_access_key_id=\(.*\)/\1/ ; t; d' ~/.aws/credentials)
          export AWS_SECRET_ACCESS_KEY=$(sed 's/aws_secret_access_key=\(.*\)/\1/ ; t; d' ~/.aws/credentials)
          NIX_PATH=nixpkgs=. ./maintainers/scripts/copy-tarballs.pl \
            --expr '(import <nixpkgs/pkgs/top-level/release.nix> { scrubJobs = false; })' \
            --exclude 'registry.npmjs.org|mirror://kde|mirror://xorg|mirror://kernel|mirror://hackage|mirror://gnome|mirror://apache|mirror://mozilla|pypi.python.org'
        '';
      startAt = "05:30";
    };

}
