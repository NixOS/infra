#!/usr/bin/env bash

# Use this script to deploy the initial keys when bootstrapping a new machines.

set -euo pipefail
tmpDir=$(mktemp -d)
sshDir="$tmpDir/etc/ssh"
mkdir -p "$sshDir"
trap 'rm -rf "$tmpDir"' EXIT

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

for keyname in ssh_host_ed25519_key ssh_host_ed25519_key.pub; do
  if [[ $keyname == *.pub ]]; then
    umask 0133
  else
    umask 0177
  fi
  sops --extract '["'$keyname'"]' --decrypt "$SCRIPT_DIR/../../secrets/staging-hydra-hostkeys.yaml" >"$sshDir/$keyname"
done
nix run nixpkgs#nixos-anywhere -- --extra-files "$tmpDir" -f .#staging-hydra root@157.180.25.203
