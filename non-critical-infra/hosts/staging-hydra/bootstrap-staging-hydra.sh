#!/usr/bin/env bash

# Use this script to deploy the initial keys when bootstrapping a new machine.

set -euo pipefail
tmpDir=$(mktemp -d)
sshDir="$tmpDir/etc/ssh"
mkdir -p "$sshDir"
trap 'rm -rf "$tmpDir"' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

keys=(
  ssh_host_ed25519_key
  ssh_host_ed25519_key_pub
  ssh_host_rsa_key
  ssh_host_rsa_key_pub
)
for keyname in "${keys[@]}"; do
  if [[ $keyname == *.pub ]]; then
    umask 0133
  else
    umask 0177
  fi
  sops --extract '["'"$keyname"'"]' --decrypt "$SCRIPT_DIR/../../secrets/staging-hydra-hostkeys.yaml" >"$sshDir/$keyname"
done
# Mounted NixOS minimal image
nix run nixpkgs#nixos-anywhere -- --extra-files "$tmpDir" -f .#staging-hydra nixos@157.180.25.203
